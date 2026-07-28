import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

typedef NowProvider = DateTime Function();

class GardenStore extends ChangeNotifier {
  GardenStore({
    this.persistence = true,
    NowProvider? nowProvider,
    this.seedOnFirstLaunch = true,
  }) : nowProvider = nowProvider ?? DateTime.now;

  static const storageKey = 'garden_state_v2';
  static const legacyStorageKey = 'garden_state_v1';
  static const actionDewReward = 5;
  static const actionCareReward = 10;
  static const carePerLevel = 100;

  final bool persistence;
  final bool seedOnFirstLaunch;
  final NowProvider nowProvider;
  final List<Habit> habits = [];
  final Map<String, int> inventory = {'Mossy stone': 1};
  final List<PlacedGardenItem> placedItems = [];
  final Set<String> ownedBackgrounds = {'morning_meadow'};
  String selectedBackgroundId = 'morning_meadow';
  GardenSettings settings = GardenSettings();
  int dew = 30;
  int carePoints = 0;
  bool loaded = false;
  String? loadError;

  DateTime get today => dateOnly(nowProvider());
  List<Habit> get activeHabits =>
      habits.where((habit) => !habit.archived).toList();
  List<Habit> habitsFor(DateTime day) =>
      activeHabits.where((habit) => habit.scheduledOn(day)).toList();
  List<Habit> get todayHabits => habitsFor(today);
  List<Habit> get archivedHabits =>
      habits.where((habit) => habit.archived).toList();
  int get todayDone =>
      todayHabits.where((habit) => habit.completedOn(today)).length;
  int get todayActions =>
      todayHabits.fold(0, (sum, habit) => sum + habit.countOn(today));
  int get totalCompletions =>
      habits.fold(0, (sum, habit) => sum + habit.totalCompletions);
  double get dayProgress =>
      todayHabits.isEmpty ? 0 : todayDone / todayHabits.length;
  int get longestStreak => activeHabits.isEmpty
      ? 0
      : activeHabits
            .map((habit) => habit.streakAt(today))
            .reduce((a, b) => a > b ? a : b);
  int get level => 1 + carePoints ~/ carePerLevel;
  int get xp => carePoints % carePerLevel;
  int get xpNeeded => carePerLevel;
  String get gardenerName => settings.gardenerName.trim().isEmpty
      ? 'Gardener'
      : settings.gardenerName.trim();
  String get gardenName => settings.gardenName.trim().isEmpty
      ? 'My cozy garden'
      : settings.gardenName.trim();
  Set<String> get ownedItems => inventory.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toSet();
  GardenBackground get selectedBackground => gardenBackgrounds.firstWhere(
    (background) => background.id == selectedBackgroundId,
    orElse: () => gardenBackgrounds.first,
  );

  int quantityOwned(String itemName) => inventory[itemName] ?? 0;
  int placedCount(String itemName) =>
      placedItems.where((item) => item.itemName == itemName).length;
  int availableCount(String itemName) =>
      (quantityOwned(itemName) - placedCount(itemName)).clamp(0, 999999);

  Future<void> load() async {
    if (loaded) return;
    if (!persistence) {
      if (seedOnFirstLaunch) _seed();
      settings.onboardingComplete = true;
      loaded = true;
      notifyListeners();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      final legacyRaw = prefs.getString(legacyStorageKey);
      if (raw == null && legacyRaw == null) {
        if (seedOnFirstLaunch) _seed();
      } else {
        _hydrate(jsonDecode(raw ?? legacyRaw!) as Map<String, dynamic>);
        if (raw == null) {
          settings.onboardingComplete = true;
          await _save();
        }
      }
    } catch (error) {
      loadError =
          'Your saved garden could not be read. A fresh garden was opened instead.';
      habits.clear();
      if (seedOnFirstLaunch) _seed();
    }
    loaded = true;
    notifyListeners();
  }

  void _hydrate(Map<String, dynamic> data) {
    habits
      ..clear()
      ..addAll(
        (data['habits'] as List? ?? const []).map(
          (value) => Habit.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    inventory.clear();
    final rawInventory = data['inventory'];
    if (rawInventory is Map) {
      for (final entry in rawInventory.entries) {
        inventory[entry.key.toString()] = (entry.value as num).toInt();
      }
    } else {
      for (final name in List<String>.from(
        data['ownedItems'] as List? ?? const ['Mossy stone'],
      )) {
        inventory[name] = (inventory[name] ?? 0) + 1;
      }
    }
    placedItems
      ..clear()
      ..addAll(
        (data['placedItems'] as List? ?? const []).map(
          (value) => PlacedGardenItem.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      );
    ownedBackgrounds
      ..clear()
      ..add('morning_meadow')
      ..addAll(
        List<String>.from(data['ownedBackgrounds'] as List? ?? const []),
      );
    final savedBackground =
        data['selectedBackgroundId'] as String? ?? 'morning_meadow';
    selectedBackgroundId = ownedBackgrounds.contains(savedBackground)
        ? savedBackground
        : 'morning_meadow';
    dew = (data['dew'] as num?)?.toInt() ?? 30;
    settings = GardenSettings.fromJson(
      data['settings'] == null
          ? null
          : Map<String, dynamic>.from(data['settings'] as Map),
    );
    if (data.containsKey('carePoints')) {
      carePoints = (data['carePoints'] as num?)?.toInt() ?? 0;
    } else {
      final oldLevel = (data['level'] as num?)?.toInt() ?? 1;
      final oldXp = (data['xp'] as num?)?.toInt() ?? 0;
      carePoints = ((oldLevel - 1) * carePerLevel) + oldXp;
    }
  }

  void _seed() {
    if (habits.isNotEmpty) return;
    habits.addAll([
      Habit(
        id: 'water',
        name: 'Drink a glass of water',
        emoji: '💧',
        type: HabitType.body,
      ),
      Habit(
        id: 'walk',
        name: 'Take a mindful walk',
        emoji: '🌿',
        type: HabitType.mind,
      ),
      Habit(
        id: 'tidy',
        name: 'Tidy for 5 minutes',
        emoji: '🧺',
        type: HabitType.home,
        scheduledWeekdays: {1, 3, 5},
      ),
    ]);
  }

  void incrementHabit(Habit habit, {DateTime? on}) {
    final day = dateOnly(on ?? today);
    final key = dayKey(day);
    final current = habit.completionCounts[key] ?? 0;
    if (current >= habit.target) return;
    habit.completionCounts[key] = current + 1;
    dew += actionDewReward;
    carePoints += actionCareReward;
    _changed();
  }

  void decrementHabit(Habit habit, {DateTime? on}) {
    final key = dayKey(on ?? today);
    final current = habit.completionCounts[key] ?? 0;
    if (current <= 0) return;
    if (current == 1) {
      habit.completionCounts.remove(key);
    } else {
      habit.completionCounts[key] = current - 1;
    }
    dew = (dew - actionDewReward).clamp(0, 999999);
    carePoints = (carePoints - actionCareReward).clamp(0, 999999);
    _changed();
  }

  void toggleHabit(Habit habit) {
    if (habit.completedOn(today)) {
      decrementHabit(habit);
    } else {
      incrementHabit(habit);
    }
  }

  Habit addHabit(
    String name,
    String emoji,
    HabitType type, {
    int target = 1,
    Set<int>? scheduledWeekdays,
  }) {
    final habit = Habit(
      id: nowProvider().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      emoji: emoji,
      type: type,
      target: target,
      scheduledWeekdays: scheduledWeekdays,
      createdDate: dayKey(today),
    );
    habits.add(habit);
    _changed();
    return habit;
  }

  void updateHabit(
    Habit habit, {
    required String name,
    required String emoji,
    required HabitType type,
    required int target,
    required Set<int> scheduledWeekdays,
  }) {
    habit
      ..name = name.trim()
      ..emoji = emoji
      ..type = type
      ..target = target
      ..scheduledWeekdays = Set<int>.from(scheduledWeekdays);
    _changed();
  }

  void archiveHabit(Habit habit) {
    habit.archived = true;
    _changed();
  }

  void restoreHabit(Habit habit) {
    habit.archived = false;
    _changed();
  }

  void deleteHabit(Habit habit) {
    habits.remove(habit);
    _changed();
  }

  bool buy(GardenItem item) {
    if (dew < item.cost) return false;
    dew -= item.cost;
    inventory[item.name] = quantityOwned(item.name) + 1;
    _changed();
    return true;
  }

  bool placeItem(String itemName, {double x = .5, double y = .52}) {
    if (availableCount(itemName) <= 0) return false;
    placedItems.add(
      PlacedGardenItem(
        id: '${nowProvider().microsecondsSinceEpoch}_${placedItems.length}',
        itemName: itemName,
        x: x,
        y: y,
      ),
    );
    _changed();
    return true;
  }

  void movePlacedItem(String id, double x, double y) {
    transformPlacedItem(id, x: x, y: y);
  }

  void transformPlacedItem(
    String id, {
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    final index = placedItems.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final item = placedItems[index];
    if (x != null) item.x = x.clamp(.06, .94);
    if (y != null) item.y = y.clamp(.18, .96);
    if (scale != null) item.scale = scale.clamp(.55, 1.8);
    if (rotation != null) item.rotation = rotation;
    _changed();
  }

  void removePlacedItem(String id) {
    final before = placedItems.length;
    placedItems.removeWhere((item) => item.id == id);
    if (placedItems.length != before) _changed();
  }

  bool buyBackground(GardenBackground background) {
    if (ownedBackgrounds.contains(background.id) || dew < background.cost) {
      return false;
    }
    dew -= background.cost;
    ownedBackgrounds.add(background.id);
    _changed();
    return true;
  }

  bool selectBackground(String id) {
    if (!ownedBackgrounds.contains(id) || selectedBackgroundId == id) {
      return false;
    }
    selectedBackgroundId = id;
    _changed();
    return true;
  }

  void completeOnboarding(String name) {
    settings
      ..gardenerName = name.trim()
      ..onboardingComplete = true;
    _changed();
  }

  void updateSettings({
    String? name,
    String? gardenName,
    bool? gentleReminders,
    bool? soundEnabled,
    bool? darkMode,
  }) {
    if (name != null) settings.gardenerName = name.trim();
    if (gardenName != null && gardenName.trim().isNotEmpty) {
      settings.gardenName = gardenName.trim();
    }
    if (gentleReminders != null) settings.gentleReminders = gentleReminders;
    if (soundEnabled != null) settings.soundEnabled = soundEnabled;
    if (darkMode != null) settings.darkMode = darkMode;
    _changed();
  }

  Future<void> resetGarden() async {
    habits.clear();
    inventory
      ..clear()
      ..['Mossy stone'] = 1;
    placedItems.clear();
    ownedBackgrounds
      ..clear()
      ..add('morning_meadow');
    selectedBackgroundId = 'morning_meadow';
    dew = 30;
    carePoints = 0;
    settings = GardenSettings();
    _seed();
    loaded = true;
    if (persistence) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
      await prefs.remove(legacyStorageKey);
    }
    notifyListeners();
  }

  void clearLoadError() {
    loadError = null;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 3,
    'habits': habits.map((habit) => habit.toJson()).toList(),
    'inventory': inventory,
    'placedItems': placedItems.map((item) => item.toJson()).toList(),
    'ownedBackgrounds': ownedBackgrounds.toList(),
    'selectedBackgroundId': selectedBackgroundId,
    'dew': dew,
    'carePoints': carePoints,
    'settings': settings.toJson(),
  };

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    if (!persistence) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, jsonEncode(toJson()));
    } catch (_) {
      loadError = 'Changes are visible, but could not be saved on this device.';
      notifyListeners();
    }
  }
}
