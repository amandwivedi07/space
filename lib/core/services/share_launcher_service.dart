import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../extensions/string_x.dart';
import 'logger_service.dart';

/// Outward deep links: WhatsApp invites, SMS nudges, opening shared links.
class ShareLauncherService {
  Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Log.w('Could not launch $uri: $e');
      return false;
    }
  }

  Future<bool> whatsApp({required String phone, required String message}) =>
      _open(Uri.parse(
          'https://wa.me/${phone.digitsOnly}?text=${Uri.encodeComponent(message)}'));

  Future<bool> sms({required String phone, required String message}) =>
      _open(Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}'));

  Future<bool> openLink(String url) {
    final target = url.startsWith('http') ? url : 'https://$url';
    return _open(Uri.parse(target));
  }
}

final shareLauncherProvider =
    Provider<ShareLauncherService>((ref) => ShareLauncherService());
