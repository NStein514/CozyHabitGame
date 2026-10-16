import 'package:cozy_habit_garden/models.dart';
import 'package:cozy_habit_garden/widgets/garden_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all supported symbols use artwork with accessible names', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final symbol in GardenIcon.symbols) GardenIcon(symbol),
              for (final item in gardenCatalog) GardenIcon(item.emoji),
              const GardenIcon('🍃'),
              const GardenIcon('♥'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsNothing);
    expect(find.bySemanticsLabel('Water'), findsOneWidget);
    expect(find.bySemanticsLabel('Mossy stone'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('saved habits retain symbols while unknown symbols get artwork', (
    tester,
  ) async {
    final habit = Habit(
      id: 'old',
      name: 'Read',
      emoji: '📖',
      type: HabitType.mind,
    );
    final restored = Habit.fromJson(habit.toJson());
    expect(restored.emoji, '📖');
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [GardenIcon(restored.emoji), const GardenIcon('unknown')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline currency and streak artwork wrap with enlarged text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(
            body: SizedBox(
              width: 180,
              child: GardenIllustratedText(
                'Buy another · 💧 100 · 🔥 3 day streak',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GardenIcon), findsNWidgets(2));
    final text = tester.widget<Text>(find.byType(Text));
    expect(
      text.textSpan!.toPlainText(includePlaceholders: false),
      'Buy another ·  100 ·  3 day streak',
    );
    expect(tester.takeException(), isNull);
  });
}
