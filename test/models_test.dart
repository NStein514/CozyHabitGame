import 'package:cozy_habit_garden/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Habit', () {
    test('tracks multi-check-in completion', () {
      final habit = Habit(
        id: 'water',
        name: 'Water',
        emoji: '💧',
        type: HabitType.body,
        target: 3,
        completionCounts: {'2026-07-20': 2, '2026-07-21': 3},
        createdDate: '2026-07-01',
      );

      expect(habit.completedOn(DateTime(2026, 7, 20)), isFalse);
      expect(habit.completedOn(DateTime(2026, 7, 21)), isTrue);
      expect(habit.totalActions, 5);
      expect(habit.totalCompletions, 1);
    });

    test('streak skips days that are not scheduled', () {
      final habit = Habit(
        id: 'tidy',
        name: 'Tidy',
        emoji: '🧺',
        type: HabitType.home,
        scheduledWeekdays: {1, 3, 5},
        completionCounts: {
          '2026-07-17': 1, // Friday
          '2026-07-20': 1, // Monday
          '2026-07-22': 1, // Wednesday
        },
        createdDate: '2026-07-01',
      );

      expect(habit.streakAt(DateTime(2026, 7, 22)), 3);
      expect(habit.streakAt(DateTime(2026, 7, 23)), 3);
    });

    test('migrates legacy completed dates', () {
      final habit = Habit.fromJson({
        'id': 'legacy',
        'name': 'Legacy habit',
        'emoji': '🌱',
        'type': 'mind',
        'target': 1,
        'completedDates': ['2026-07-20', '2026-07-21'],
      });

      expect(habit.countOn(DateTime(2026, 7, 20)), 1);
      expect(habit.totalCompletions, 2);
      expect(habit.scheduledWeekdays, hasLength(7));
    });

    test('calculates rate using only scheduled days', () {
      final habit = Habit(
        id: 'weekly',
        name: 'Weekly',
        emoji: '🌿',
        type: HabitType.mind,
        scheduledWeekdays: {1, 3},
        completionCounts: {'2026-07-20': 1},
        createdDate: '2026-07-20',
      );

      expect(habit.completionRate(DateTime(2026, 7, 22), days: 7), .5);
    });
  });

  test('shop catalogs are ordered by Dew cost', () {
    final itemCosts = gardenCatalogByDewCost()
        .map((item) => item.cost)
        .toList();
    final backgroundCosts = gardenBackgroundsByDewCost()
        .map((background) => background.cost)
        .toList();

    expect(itemCosts, orderedEquals([...itemCosts]..sort()));
    expect(backgroundCosts, orderedEquals([...backgroundCosts]..sort()));
  });
}
