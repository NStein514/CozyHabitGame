enum HabitType { body, mind, home, heart }

extension HabitTypeLabel on HabitType {
  String get label => switch (this) {
    HabitType.body => 'Body',
    HabitType.mind => 'Mind',
    HabitType.home => 'Home',
    HabitType.heart => 'Heart',
  };

  String get description => switch (this) {
    HabitType.body => 'Movement, rest, food, and hydration',
    HabitType.mind => 'Learning, reflection, and calm',
    HabitType.home => 'Your space and daily routines',
    HabitType.heart => 'Connection, creativity, and kindness',
  };
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    this.target = 1,
    Set<int>? scheduledWeekdays,
    Map<String, int>? completionCounts,
    this.archived = false,
    String? createdDate,
  }) : scheduledWeekdays = scheduledWeekdays ?? {1, 2, 3, 4, 5, 6, 7},
       completionCounts = completionCounts ?? {},
       createdDate = createdDate ?? dayKey(DateTime.now());

  final String id;
  String name;
  String emoji;
  HabitType type;
  int target;
  Set<int> scheduledWeekdays;
  Map<String, int> completionCounts;
  bool archived;
  final String createdDate;

  bool scheduledOn(DateTime day) => scheduledWeekdays.contains(day.weekday);
  int countOn(DateTime day) => completionCounts[dayKey(day)] ?? 0;
  bool completedOn(DateTime day) => countOn(day) >= target;
  int get totalActions => completionCounts.values.fold(0, (a, b) => a + b);
  int get totalCompletions =>
      completionCounts.entries.where((entry) => entry.value >= target).length;

  int streakAt(DateTime today) {
    var day = dateOnly(today);
    if (!scheduledOn(day) || !completedOn(day)) {
      day = previousScheduledDay(day);
    }
    var streak = 0;
    while (!day.isBefore(DateTime.parse(createdDate))) {
      if (!completedOn(day)) break;
      streak++;
      day = previousScheduledDay(day);
    }
    return streak;
  }

  DateTime previousScheduledDay(DateTime from) {
    var cursor = dateOnly(from).subtract(const Duration(days: 1));
    for (var attempts = 0; attempts < 7; attempts++) {
      if (scheduledOn(cursor)) return cursor;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return cursor;
  }

  double completionRate(DateTime through, {int days = 30}) {
    var due = 0;
    var completed = 0;
    final firstDay = DateTime.parse(createdDate);
    for (var offset = 0; offset < days; offset++) {
      final day = dateOnly(through).subtract(Duration(days: offset));
      if (day.isBefore(firstDay)) continue;
      if (scheduledOn(day)) {
        due++;
        if (completedOn(day)) completed++;
      }
    }
    return due == 0 ? 0 : completed / due;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'type': type.name,
    'target': target,
    'scheduledWeekdays': scheduledWeekdays.toList()..sort(),
    'completionCounts': completionCounts,
    'archived': archived,
    'createdDate': createdDate,
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final counts = <String, int>{};
    final rawCounts = json['completionCounts'];
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        counts[entry.key.toString()] = (entry.value as num).toInt();
      }
    } else {
      // Migration from the original completedDates representation.
      for (final date in List<String>.from(
        json['completedDates'] as List? ?? [],
      )) {
        counts[date] = json['target'] as int? ?? 1;
      }
    }
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      type: HabitType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => HabitType.mind,
      ),
      target: (json['target'] as num?)?.toInt() ?? 1,
      scheduledWeekdays: Set<int>.from(
        json['scheduledWeekdays'] as List? ?? const [1, 2, 3, 4, 5, 6, 7],
      ),
      completionCounts: counts,
      archived: json['archived'] as bool? ?? false,
      createdDate: json['createdDate'] as String?,
    );
  }
}

class GardenSettings {
  GardenSettings({
    this.gardenerName = '',
    this.gardenName = 'My cozy garden',
    this.onboardingComplete = false,
    this.gentleReminders = true,
    this.soundEnabled = true,
    this.darkMode = false,
  });

  String gardenerName;
  String gardenName;
  bool onboardingComplete;
  bool gentleReminders;
  bool soundEnabled;
  bool darkMode;

  Map<String, dynamic> toJson() => {
    'gardenerName': gardenerName,
    'gardenName': gardenName,
    'onboardingComplete': onboardingComplete,
    'gentleReminders': gentleReminders,
    'soundEnabled': soundEnabled,
    'darkMode': darkMode,
  };

  factory GardenSettings.fromJson(Map<String, dynamic>? json) => GardenSettings(
    gardenerName: json?['gardenerName'] as String? ?? '',
    gardenName: json?['gardenName'] as String? ?? 'My cozy garden',
    onboardingComplete: json?['onboardingComplete'] as bool? ?? false,
    gentleReminders: json?['gentleReminders'] as bool? ?? true,
    soundEnabled: json?['soundEnabled'] as bool? ?? true,
    darkMode: json?['darkMode'] as bool? ?? false,
  );
}

class GardenItem {
  const GardenItem({
    required this.name,
    required this.emoji,
    required this.cost,
    required this.description,
    required this.kind,
    this.assetPath,
  });
  final String name;
  final String emoji;
  final int cost;
  final String description;
  final String kind;
  final String? assetPath;
}

class PlacedGardenItem {
  PlacedGardenItem({
    required this.id,
    required this.itemName,
    required this.x,
    required this.y,
    this.scale = 1,
    this.rotation = 0,
  });

  final String id;
  final String itemName;
  double x;
  double y;
  double scale;
  double rotation;

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemName': itemName,
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
  };

  factory PlacedGardenItem.fromJson(Map<String, dynamic> json) =>
      PlacedGardenItem(
        id: json['id'] as String,
        itemName: json['itemName'] as String,
        x: (json['x'] as num?)?.toDouble() ?? .5,
        y: (json['y'] as num?)?.toDouble() ?? .65,
        scale: (json['scale'] as num?)?.toDouble() ?? 1,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      );
}

class GardenBackground {
  const GardenBackground({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
    required this.assetPath,
  });

  final String id;
  final String name;
  final int cost;
  final String description;
  final String assetPath;
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

const gardenCatalog = <GardenItem>[
  GardenItem(
    name: 'Mossy stone',
    emoji: '🪨',
    cost: 20,
    description: 'A soft place for beetles to rest.',
    kind: 'Decor',
    assetPath: 'assets/images/collectibles/mossy_stone.png',
  ),
  GardenItem(
    name: 'Daisy patch',
    emoji: '🌼',
    cost: 35,
    description: 'Tiny suns for your garden path.',
    kind: 'Plant',
    assetPath: 'assets/images/plants/daisies.png',
  ),
  GardenItem(
    name: 'Golden sunflower',
    emoji: '🌻',
    cost: 50,
    description: 'A tall, sunny bloom that turns every morning golden.',
    kind: 'Plant',
    assetPath: 'assets/images/plants/sunflower.png',
  ),
  GardenItem(
    name: 'Pink tulips',
    emoji: '🌷',
    cost: 65,
    description: 'Three blush blooms painted by the first light of spring.',
    kind: 'Plant',
    assetPath: 'assets/images/plants/tulips.png',
  ),
  GardenItem(
    name: 'Little snail',
    emoji: '🐌',
    cost: 55,
    description: 'A patient new garden friend.',
    kind: 'Creature',
    assetPath: 'assets/images/collectibles/snail.png',
  ),
  GardenItem(
    name: 'Bird bath',
    emoji: '⛲',
    cost: 75,
    description: 'Invites birds in for a splash.',
    kind: 'Decor',
    assetPath: 'assets/images/collectibles/bird_bath.png',
  ),
  GardenItem(
    name: 'Blue butterfly',
    emoji: '🦋',
    cost: 100,
    description: 'Appears when the garden feels calm.',
    kind: 'Creature',
    assetPath: 'assets/images/collectibles/butterfly.png',
  ),
  GardenItem(
    name: 'Cherry tree',
    emoji: '🌸',
    cost: 140,
    description: 'A canopy made for slow afternoons.',
    kind: 'Plant',
    assetPath: 'assets/images/plants/cherry_tree.png',
  ),
  GardenItem(
    name: 'Cozy cottage',
    emoji: '🏡',
    cost: 200,
    description: 'The warm heart of your little garden.',
    kind: 'Decor',
    assetPath: 'assets/images/collectibles/cottage.png',
  ),
  GardenItem(
    name: 'Red fox',
    emoji: '🦊',
    cost: 260,
    description: 'A shy friend who visits at dusk.',
    kind: 'Creature',
    assetPath: 'assets/images/collectibles/fox.png',
  ),
  GardenItem(
    name: 'Moon lantern',
    emoji: '🏮',
    cost: 320,
    description: 'A warm glow for quiet evenings.',
    kind: 'Decor',
    assetPath: 'assets/images/collectibles/lantern.png',
  ),
  GardenItem(
    name: 'Sleepy cat',
    emoji: '🐈',
    cost: 400,
    description: 'Claims the sunniest corner as its own.',
    kind: 'Creature',
    assetPath: 'assets/images/collectibles/cat.png',
  ),
  GardenItem(
    name: 'Purple lavender',
    emoji: '💜',
    cost: 80,
    description: 'A fragrant purple cluster that sways in the breeze.',
    kind: 'Plant',
    assetPath: 'assets/images/plants/lavender.png',
  ),
  GardenItem(
    name: 'Blue hydrangea',
    emoji: '🩵',
    cost: 110,
    description: 'A cloud of soft blue storybook blossoms.',
    kind: 'Plant',
    assetPath: 'assets/images/plants/hydrangea.png',
  ),
  GardenItem(
    name: 'Moon mushroom patch',
    emoji: '🍄',
    cost: 125,
    description: 'Tiny moonlit caps for a softly magical corner.',
    kind: 'Plant',
    assetPath: 'assets/images/plants/moon_mushrooms.png',
  ),
  GardenItem(
    name: 'Acorn bench',
    emoji: '🪵',
    cost: 90,
    description: 'A little wooden seat made for unhurried afternoons.',
    kind: 'Decor',
    assetPath: 'assets/images/collectibles/acorn_bench.png',
  ),
  GardenItem(
    name: 'Tiny watering can',
    emoji: '🪴',
    cost: 70,
    description: 'A cheerful can ready for the next caring moment.',
    kind: 'Decor',
    assetPath: 'assets/images/collectibles/watering_can.png',
  ),
  GardenItem(
    name: 'Garden wind chime',
    emoji: '🎐',
    cost: 150,
    description: 'A gentle chime that turns every breeze into music.',
    kind: 'Decor',
    assetPath: 'assets/images/collectibles/wind_chime.png',
  ),
];

const gardenBackgrounds = <GardenBackground>[
  GardenBackground(
    id: 'morning_meadow',
    name: 'Morning Meadow',
    cost: 0,
    description: 'Your bright, peaceful garden at the start of a new day.',
    assetPath: 'assets/images/garden/bare_garden.png',
  ),
  GardenBackground(
    id: 'twilight_hollow',
    name: 'Twilight Hollow',
    cost: 180,
    description: 'A dreamy violet garden beneath the first evening stars.',
    assetPath: 'assets/images/garden/twilight_garden.png',
  ),
  GardenBackground(
    id: 'amber_autumn',
    name: 'Amber Autumn',
    cost: 220,
    description: 'Golden leaves and warm light for an everlasting fall day.',
    assetPath: 'assets/images/garden/autumn_garden.png',
  ),
  GardenBackground(
    id: 'mushroom_grove',
    name: 'Mushroom Grove',
    cost: 260,
    description: 'A firefly-lit woodland clearing beneath a lavender moon.',
    assetPath: 'assets/images/garden/mushroom_grove.png',
  ),
  GardenBackground(
    id: 'clover_coast',
    name: 'Clover Coast',
    cost: 300,
    description: 'A bright, breezy garden perched above a turquoise sea.',
    assetPath: 'assets/images/garden/clover_coast.png',
  ),
  GardenBackground(
    id: 'celestial_glasshouse',
    name: 'Celestial Glasshouse',
    cost: 360,
    description: 'A starlit conservatory with moonlight under glass.',
    assetPath: 'assets/images/garden/celestial_glasshouse.png',
  ),
];

List<GardenItem> gardenCatalogByDewCost() => [...gardenCatalog]
  ..sort((a, b) {
    final byCost = a.cost.compareTo(b.cost);
    return byCost != 0 ? byCost : a.name.compareTo(b.name);
  });

List<GardenBackground> gardenBackgroundsByDewCost() =>
    [...gardenBackgrounds]..sort((a, b) {
      final byCost = a.cost.compareTo(b.cost);
      return byCost != 0 ? byCost : a.name.compareTo(b.name);
    });
