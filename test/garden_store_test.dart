import 'dart:convert';

import 'package:cozy_habit_garden/garden_store.dart';
import 'package:cozy_habit_garden/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late GardenStore store;
  final monday = DateTime(2026, 7, 20, 9);

  setUp(() async {
    store = GardenStore(persistence: false, nowProvider: () => monday);
    await store.load();
  });

  test('filters today habits by weekday schedule', () {
    expect(
      store.todayHabits.map((habit) => habit.id),
      containsAll(['water', 'walk', 'tidy']),
    );
    final tuesdayStore = GardenStore(
      persistence: false,
      nowProvider: () => DateTime(2026, 7, 21),
    );
    tuesdayStore.load();
    expect(
      tuesdayStore.todayHabits.map((habit) => habit.id),
      isNot(contains('tidy')),
    );
  });

  test('completion rewards are capped at the daily target and reversible', () {
    final habit = store.addHabit('Hydrate', '💧', HabitType.body, target: 2);
    final startingDew = store.dew;

    store.incrementHabit(habit);
    store.incrementHabit(habit);
    store.incrementHabit(habit);

    expect(habit.countOn(monday), 2);
    expect(store.dew, startingDew + GardenStore.actionDewReward * 2);
    expect(store.carePoints, GardenStore.actionCareReward * 2);
    store.decrementHabit(habit);
    expect(habit.countOn(monday), 1);
    expect(store.carePoints, GardenStore.actionCareReward);
  });

  test('progression is deterministic across level boundaries', () {
    final habit = store.habits.first;
    for (var index = 0; index < 10; index++) {
      habit.completionCounts[dayKey(monday.subtract(Duration(days: index)))] =
          1;
      store.carePoints += GardenStore.actionCareReward;
    }
    expect(store.level, 2);
    expect(store.xp, 0);
    store.carePoints -= GardenStore.actionCareReward;
    expect(store.level, 1);
    expect(store.xp, 90);
  });

  test('archive preserves history and restore makes habit active', () {
    final habit = store.habits.first;
    store.incrementHabit(habit);
    store.archiveHabit(habit);
    expect(store.activeHabits, isNot(contains(habit)));
    expect(habit.totalCompletions, 1);
    store.restoreHabit(habit);
    expect(store.activeHabits, contains(habit));
  });

  test('purchases multiple copies without automatically placing them', () {
    store.dew = 100;
    final item = gardenCatalog[1];
    expect(store.buy(item), isTrue);
    expect(store.dew, 100 - item.cost);
    expect(store.buy(item), isTrue);
    expect(store.quantityOwned(item.name), 2);
    expect(store.placedItems, isEmpty);
    expect(store.dew, 100 - item.cost * 2);
    expect(store.buy(item), isFalse);
  });

  test('places, moves, and returns individual inventory copies', () {
    store.dew = 100;
    final item = gardenCatalog[1];
    store.buy(item);
    store.buy(item);

    expect(store.placeItem(item.name, x: .3, y: .5), isTrue);
    expect(store.placeItem(item.name, x: .7, y: .7), isTrue);
    expect(store.placeItem(item.name), isFalse);
    expect(store.availableCount(item.name), 0);

    final first = store.placedItems.first;
    store.movePlacedItem(first.id, .8, .4);
    expect(first.x, .8);
    expect(first.y, .4);
    store.transformPlacedItem(first.id, scale: 1.5, rotation: .75);
    expect(first.scale, 1.5);
    expect(first.rotation, .75);
    expect((store.toJson()['placedItems'] as List).first['rotation'], .75);

    store.removePlacedItem(first.id);
    expect(store.availableCount(item.name), 1);
    expect(store.quantityOwned(item.name), 2);
  });

  test('backgrounds are purchased once and explicitly selected', () {
    store.dew = 500;
    final twilight = gardenBackgrounds[1];

    expect(store.buyBackground(twilight), isTrue);
    expect(store.selectedBackgroundId, 'morning_meadow');
    expect(store.buyBackground(twilight), isFalse);
    expect(store.selectBackground(twilight.id), isTrue);
    expect(store.selectedBackgroundId, twilight.id);
    expect(store.toJson()['selectedBackgroundId'], twilight.id);
  });

  test('dark mode preference is persisted', () {
    store.updateSettings(darkMode: true);
    expect(store.settings.darkMode, isTrue);
    expect(
      (store.toJson()['settings'] as Map<String, dynamic>)['darkMode'],
      isTrue,
    );
  });

  test('loads and migrates legacy persisted state', () async {
    SharedPreferences.setMockInitialValues({
      GardenStore.legacyStorageKey: jsonEncode({
        'habits': [
          {
            'id': 'old',
            'name': 'Old habit',
            'emoji': '🌱',
            'type': 'mind',
            'target': 1,
            'completedDates': ['2026-07-20'],
          },
        ],
        'ownedItems': ['Daisy patch'],
        'dew': 44,
        'level': 2,
        'xp': 20,
      }),
    });
    final persisted = GardenStore(persistence: true, nowProvider: () => monday);
    await persisted.load();

    expect(persisted.habits.single.completedOn(monday), isTrue);
    expect(persisted.carePoints, 120);
    expect(persisted.quantityOwned('Daisy patch'), 1);
    expect(persisted.placedItems, isEmpty);
    expect(persisted.settings.onboardingComplete, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(GardenStore.storageKey), isNotNull);
  });
}
