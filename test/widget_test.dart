import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:space_flutter/main.dart';

void main() {
  testWidgets('Space boots to splash and settles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: SpaceApp()));

    // Splash brand mark.
    expect(find.text('Space'), findsOneWidget);

    // First run: auth restores and redirects to onboarding.
    await tester.pumpAndSettle();
    expect(find.text('Your quiet self'), findsOneWidget);
  });
}
