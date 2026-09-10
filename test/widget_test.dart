import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_app/data/local/local_storage_service.dart';
import 'package:real_estate_app/main.dart';
import 'package:real_estate_app/state/app_state_providers.dart';

void main() {
  testWidgets('RealEstateApp OLX marketplace and bilingual toggle verification', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
        ],
        child: const RealEstateApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify OLX Header and English default strings
    expect(find.text('Find Your Dream Land in Tenkasi'), findsOneWidget);
    expect(find.text('Property Categories'), findsOneWidget);
    expect(find.text('Featured Properties'), findsOneWidget);
    expect(find.text('Latest Listings'), findsOneWidget);
    expect(find.text('SELL'), findsOneWidget);

    // 2. Test Language Switcher Toggle
    final languageSwitchFinder = find.byTooltip('English').evaluate().isEmpty
        ? find.text('English')
        : find.byTooltip('English');

    expect(languageSwitchFinder, findsOneWidget);
    await tester.tap(languageSwitchFinder);
    await tester.pumpAndSettle();

    // Verify Tamil strings are now rendered
    expect(find.text('தென்காசியில் உங்கள் கனவு நிலத்தைக் கண்டறியுங்கள்'), findsOneWidget);
    expect(find.text('விற்பனை'), findsOneWidget);
    expect(find.text('சொத்து வகைகள்'), findsOneWidget);

    // Toggle back to English
    final tamilSwitchFinder = find.text('தமிழ்');
    expect(tamilSwitchFinder, findsOneWidget);
    await tester.tap(tamilSwitchFinder);
    await tester.pumpAndSettle();

    expect(find.text('Find Your Dream Land in Tenkasi'), findsOneWidget);
    expect(find.text('SELL'), findsOneWidget);

    // 3. Test Tapping the center "SELL" button to open PostAdWizard
    final sellButtonFinder = find.text('SELL');
    await tester.tap(sellButtonFinder);
    await tester.pumpAndSettle();

    // Verify Post Ad Wizard opened with Step 1
    expect(find.text('Post Your Property Ad'), findsOneWidget);
    expect(find.text('Select Category'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);

    // Close the wizard
    final closeButtonFinder = find.byIcon(Icons.close_rounded);
    expect(closeButtonFinder, findsOneWidget);
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Back to Home
    expect(find.text('Find Your Dream Land in Tenkasi'), findsOneWidget);
  });
}
