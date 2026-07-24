import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../models.dart';
import '../screens/garden_shell.dart';
import '../theme/cozy_theme.dart';

/// A preview-only harness for exercising the entire application in one place.
///
/// It uses in-memory state and a controllable clock. Nothing done here reads or
/// overwrites the user's real saved garden.
class GardenPlayground extends StatefulWidget {
  const GardenPlayground({super.key});

  @override
  State<GardenPlayground> createState() => _GardenPlaygroundState();
}

class _GardenPlaygroundState extends State<GardenPlayground> {
  late final _PlaygroundClock _clock;
  late final _PlaygroundStore _store;

  @override
  void initState() {
    super.initState();
    _clock = _PlaygroundClock(DateTime(2026, 7, 20, 9));
    _store = _PlaygroundStore(_clock)..load();
    _store.updateSettings(name: 'Rowan');
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cozy Habit Garden Playground',
      debugShowCheckedModeBanner: false,
      theme: buildCozyTheme(),
      home: AnimatedBuilder(
        animation: _store,
        builder: (context, child) {
          if (!_store.loaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Stack(
            children: [
              GardenShell(store: _store),
              Positioned(
                bottom: 86,
                right: 12,
                child: _PlaygroundButton(
                  onPressed: () => _showControls(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showControls(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => AnimatedBuilder(
        animation: _store,
        builder: (context, child) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🧪', style: TextStyle(fontSize: 30)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Garden test controls',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Text(
                              'Preview-only · real app data is never changed',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DateController(
                    date: _clock.value,
                    onPrevious: () => _store.moveDate(-1),
                    onNext: () => _store.moveDate(1),
                  ),
                  const SizedBox(height: 12),
                  _ControlAction(
                    icon: Icons.check_circle_outline,
                    title: 'Complete today’s habits',
                    subtitle: 'Fills every check-in due on this date',
                    onTap: _store.completeCurrentDay,
                  ),
                  _ControlAction(
                    icon: Icons.auto_graph_rounded,
                    title: 'Simulate a healthy week',
                    subtitle:
                        'Builds seven days of history, streaks, dew, and growth',
                    onTap: _store.simulateWeek,
                  ),
                  _ControlAction(
                    icon: Icons.water_drop_outlined,
                    title: 'Add 100 dew',
                    subtitle: 'Try purchasing decorations and creatures',
                    onTap: () => _store.grantDew(100),
                  ),
                  _ControlAction(
                    icon: Icons.add_task_rounded,
                    title: 'Add a multi-check-in habit',
                    subtitle:
                        'Creates “Stretch break” with three daily check-ins',
                    onTap: _store.addDemoHabit,
                  ),
                  const Divider(height: 24),
                  _ControlAction(
                    icon: Icons.restart_alt_rounded,
                    title: 'Reset playground',
                    subtitle: 'Return to the original habits and Monday date',
                    destructive: true,
                    onTap: _store.resetPlayground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaygroundClock {
  _PlaygroundClock(this.value);
  DateTime value;
}

class _PlaygroundStore extends GardenStore {
  _PlaygroundStore(this.clock)
    : super(persistence: false, nowProvider: () => clock.value);

  final _PlaygroundClock clock;

  void moveDate(int dayDelta) {
    clock.value = clock.value.add(Duration(days: dayDelta));
    notifyListeners();
  }

  void completeCurrentDay() {
    for (final habit in todayHabits) {
      while (habit.countOn(today) < habit.target) {
        incrementHabit(habit);
      }
    }
  }

  void simulateWeek() {
    final endDate = today;
    for (var offset = 6; offset >= 0; offset--) {
      final day = endDate.subtract(Duration(days: offset));
      for (final habit in habitsFor(day)) {
        while (habit.countOn(day) < habit.target) {
          incrementHabit(habit, on: day);
        }
      }
    }
    notifyListeners();
  }

  void grantDew(int amount) {
    dew += amount;
    notifyListeners();
  }

  void addDemoHabit() {
    if (activeHabits.any((habit) => habit.name == 'Stretch break')) return;
    addHabit(
      'Stretch break',
      '🧘',
      HabitType.body,
      target: 3,
      scheduledWeekdays: {1, 2, 3, 4, 5},
    );
  }

  Future<void> resetPlayground() async {
    clock.value = DateTime(2026, 7, 20, 9);
    await resetGarden();
    settings
      ..gardenerName = 'Rowan'
      ..onboardingComplete = true;
    notifyListeners();
  }
}

class _PlaygroundButton extends StatelessWidget {
  const _PlaygroundButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: forest,
    elevation: 5,
    shadowColor: forest.withValues(alpha: .35),
    borderRadius: BorderRadius.circular(99),
    child: InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onPressed,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧪', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text(
              'Test',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DateController extends StatelessWidget {
  const _DateController({
    required this.date,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1EE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'SIMULATED DATE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: forest,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${months[date.month - 1]} ${date.day}, ${date.year}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _ControlAction extends StatelessWidget {
  const _ControlAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: destructive ? Colors.red.shade700 : forest),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: destructive ? Colors.red.shade700 : null,
      ),
    ),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
