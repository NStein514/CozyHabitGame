import 'package:cozy_habit_garden/garden_store.dart';
import 'package:cozy_habit_garden/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'optional name remains usable with a keyboard on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final store = GardenStore(persistence: false, seedOnFirstLaunch: false);
      await store.load();
      await tester.pumpWidget(
        MaterialApp(home: OnboardingScreen(store: store)),
      );
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Robin');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Enter my garden'));
      await tester.pumpAndSettle();
      expect(store.gardenerName, 'Robin');
    },
  );
}
