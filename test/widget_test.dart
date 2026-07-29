import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:space_flutter/main.dart';

void main() {
  testWidgets('Space boots to splash then the sign-in door', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: SpaceApp()));

    // Splash brand mark.
    expect(find.text('Space'), findsWidgets);

    // With no session the router lands on the Apple/Google sign-in screen —
    // no form to fill in.
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
