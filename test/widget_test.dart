import 'package:cozy_habit_garden/garden_app.dart';
import 'package:cozy_habit_garden/garden_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GardenStore buildStore() => GardenStore(
    persistence: false,
    nowProvider: () => DateTime(2026, 7, 20, 9),
  );

  testWidgets('shows scheduled habits and completes one', (tester) async {
    final store = buildStore();
    await tester.pumpWidget(CozyGardenApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Today’s care'), findsOneWidget);
    expect(find.text('Drink a glass of water'), findsOneWidget);
    expect(find.text('0 of 3'), findsOneWidget);

    await tester.tap(find.text('Drink a glass of water'));
    await tester.pump();
    expect(find.text('1 of 3'), findsOneWidget);
    expect(store.dew, 35);
  });

  testWidgets('adds and edits a scheduled multi-check-in habit', (
    tester,
  ) async {
    final store = buildStore();
    await tester.pumpWidget(CozyGardenApp(store: store));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Plant a new habit'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Plant a new habit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Stretch');
    await tester.tap(find.byKey(const Key('habit-target-increase')));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('Plant this habit'));
    await tester.pumpAndSettle();

    expect(find.text('Stretch'), findsOneWidget);
    expect(store.habits.last.target, 2);
    await tester.longPress(find.text('Stretch'));
    await tester.pumpAndSettle();
    expect(find.text('Tend your habit'), findsOneWidget);
  });

  testWidgets('navigates through discovery, journey, history, and settings', (
    tester,
  ) async {
    final store = buildStore();
    await tester.pumpWidget(CozyGardenApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();
    expect(find.text('Mossy stone'), findsOneWidget);

    await tester.tap(find.text('Journey').last);
    await tester.pumpAndSettle();
    final tracks = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          ((widget.key! as ValueKey<String>).value).startsWith('weekly-track-'),
    );
    final fills = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          ((widget.key! as ValueKey<String>).value).startsWith('weekly-fill-'),
    );
    expect(tracks, findsNWidgets(7));
    expect(fills, findsNWidgets(7));
    final trackRect = tester.getRect(tracks.first);
    final fillRect = tester.getRect(fills.first);
    expect(fillRect.left, closeTo(trackRect.left + 3, .1));
    expect(fillRect.right, closeTo(trackRect.right - 3, .1));
    expect(fillRect.bottom, closeTo(trackRect.bottom - 3, .1));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Care history'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Archived habits'), findsOneWidget);
  });

  testWidgets('settings toggles the persisted dark theme', (tester) async {
    final store = buildStore();
    await tester.pumpWidget(CozyGardenApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dark-mode-toggle')));
    await tester.pumpAndSettle();

    expect(store.settings.darkMode, isTrue);
    final context = tester.element(find.text('Settings').first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
