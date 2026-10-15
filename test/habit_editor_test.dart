import 'package:cozy_habit_garden/garden_store.dart';
import 'package:cozy_habit_garden/widgets/habit_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<GardenStore> openEditor(WidgetTester tester) async {
    final store = GardenStore(persistence: false, seedOnFirstLaunch: false);
    await store.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showHabitEditor(context, store),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('tapping away dismisses input and X discards the new habit', (
    tester,
  ) async {
    final store = await openEditor(tester);
    final originalCount = store.habits.length;
    await tester.enterText(find.byType(TextField), 'Unsaved habit');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await tester.tap(find.text('Habit name'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    await tester.tap(find.byTooltip('Close without saving'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(store.habits.length, originalCount);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sunday-first labels preserve the correct saved weekdays', (
    tester,
  ) async {
    final store = await openEditor(tester);
    await tester.enterText(find.byType(TextField), 'Sunday care');
    await tester.ensureVisible(find.text('Repeat on'));
    const labels = ['Su', 'M', 'Tu', 'W', 'Th', 'F', 'Sa'];
    for (var i = 1; i < labels.length; i++) {
      expect(
        tester.getCenter(find.text(labels[i - 1])).dx,
        lessThan(tester.getCenter(find.text(labels[i])).dx),
      );
      await tester.ensureVisible(find.text(labels[i]));
      await tester.tap(find.text(labels[i]));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('Plant this habit'));
    await tester.tap(find.text('Plant this habit'));
    await tester.pumpAndSettle();
    expect(store.habits.last.scheduledWeekdays, {DateTime.sunday});
    expect(store.habits.last.name, 'Sunday care');
    expect(tester.takeException(), isNull);
  });
}
