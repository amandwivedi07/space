import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../firebase_options.dart';
import 'logger_service.dart';

/// Result of a social sign-in attempt.
sealed class SocialAuthResult {
  const SocialAuthResult();
}

/// The Firebase ID token to exchange with our backend for a Space session.
class SocialAuthToken extends SocialAuthResult {
  const SocialAuthToken(this.idToken);
  final String idToken;
}

/// The person backed out of the Apple/Google sheet — not an error.
class SocialAuthCancelled extends SocialAuthResult {
  const SocialAuthCancelled();
}

class SocialAuthFailed extends SocialAuthResult {
  const SocialAuthFailed(this.message);
  final String message;
}

/// Sign in with Apple / Google, both funnelled through Firebase Auth so the
/// backend only ever has to verify one kind of token.
class SocialAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// True once Firebase has been initialised by the app shell.
  bool get available {
    try {
      _auth.app;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Apple's guidelines require this button on iOS; it's hidden elsewhere.
  bool get appleAvailable => Platform.isIOS || Platform.isMacOS;

  Future<SocialAuthResult> signInWithGoogle() async {
    if (!available) return const SocialAuthFailed(_notConfigured);
    try {
      final google = GoogleSignIn.instance;
      // serverClientId lets Android mint an ID token Firebase will accept.
      // Apple platforms additionally need their own clientId — without it
      // initialize() throws before any Google UI is shown.
      await google.initialize(
        clientId: appleAvailable ? DefaultFirebaseOptions.googleIosClientId : null,
        serverClientId: DefaultFirebaseOptions.googleServerClientId,
      );
      final account = await google.authenticate();
      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      return _exchange(await _auth.signInWithCredential(credential));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const SocialAuthCancelled();
      }
      Log.w('google sign-in failed: $e');
      return const SocialAuthFailed('Google sign-in failed. Try again.');
    } catch (e) {
      Log.w('google sign-in failed: $e');
      return SocialAuthFailed(_friendly(e));
    }
  }

  Future<SocialAuthResult> signInWithApple() async {
    if (!available) return const SocialAuthFailed(_notConfigured);
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final credential = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      final result = await _auth.signInWithCredential(credential);

      // Apple sends the name ONLY on first consent — persist it immediately or
      // it is lost forever.
      final given = apple.givenName;
      if (given != null && given.isNotEmpty && result.user?.displayName == null) {
        final full = [given, apple.familyName].whereType<String>().join(' ');
        await result.user?.updateDisplayName(full);
        await result.user?.reload();
      }
      return _exchange(_auth.currentUser == null ? result : null);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const SocialAuthCancelled();
      }
      Log.w('apple sign-in failed: $e');
      return const SocialAuthFailed('Apple sign-in failed. Try again.');
    } catch (e) {
      Log.w('apple sign-in failed: $e');
      return SocialAuthFailed(_friendly(e));
    }
  }

  Future<SocialAuthResult> _exchange(UserCredential? credential) async {
    final user = credential?.user ?? _auth.currentUser;
    if (user == null) return const SocialAuthFailed('Sign-in did not complete');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      return const SocialAuthFailed('Could not verify that sign-in');
    }
    return SocialAuthToken(token);
  }

  /// Clears the Firebase session (our own tokens are cleared separately).
  Future<void> signOut() async {
    try {
      if (available) await _auth.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      Log.w('social sign-out: $e');
    }
  }

  static const _notConfigured =
      'Sign-in is not configured yet on this build.';

  /// Surface the real reason where we have one — a bare "Sign-in failed"
  /// hides configuration problems that only show up on one platform.
  String _friendly(Object e) {
    if (e is FirebaseAuthException) return e.message ?? 'Sign-in failed';
    Log.w('sign-in failure detail: $e');
    return 'Sign-in failed: $e';
  }
}

final socialAuthProvider = Provider<SocialAuthService>((ref) => SocialAuthService());
