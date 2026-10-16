import '../widgets/garden_icon.dart';
import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../models.dart';
import '../theme/cozy_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/stat_card.dart';
import 'history_screen.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key, required this.store});

  final GardenStore store;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => DateTime.now().subtract(Duration(days: 6 - index)),
    );
    return PagePadding(
      child: ListView(
        children: [
          const SectionEyebrow('Your gentle progress'),
          Text(
            'Garden journey',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 20),
          _LevelProgress(store: store),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: '🔥',
                  value: '${store.longestStreak}',
                  label: 'Best streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: '🌱',
                  value: '${store.totalCompletions}',
                  label: 'Habits tended',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'This week',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HistoryScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('History'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WeeklyChart(store: store, days: days),
          if (store.settings.gentleReminders) ...[
            const SizedBox(height: 22),
            Text(
              'Tiny reminders',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                leading: GardenIcon('🍃', size: 29),
                title: Text(
                  'Rest is part of growing',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Missing a day never erases the care you gave before.',
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.store});

  final GardenStore store;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: lightModeFill(context),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const GardenIcon('🌳', size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Garden level ${store.level}',
                    style: TextStyle(
                      color: lightModeText(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  Text(
                    '${store.xpNeeded - store.xp} care points until the next level',
                    style: TextStyle(
                      color: lightModeText(context, Colors.white70),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: store.xp / store.xpNeeded,
            minHeight: 9,
            color: butter,
            backgroundColor: Colors.white24,
          ),
        ),
      ],
    ),
  );
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.store, required this.days});

  final GardenStore store;
  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((day) {
            final count = store.habits
                .where((habit) => habit.completedOn(day))
                .length;
            final ratio = store.habits.isEmpty
                ? 0.0
                : count / store.habits.length;
            final isToday = dayKey(day) == dayKey(DateTime.now());
            return Column(
              children: [
                Container(
                  key: Key('weekly-track-${dayKey(day)}'),
                  width: 24,
                  height: 74,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EFE8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedFractionallySizedBox(
                        key: Key('weekly-fill-${dayKey(day)}'),
                        duration: const Duration(milliseconds: 500),
                        widthFactor: 1,
                        heightFactor: ratio.clamp(0.0, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: ColoredBox(color: isToday ? peach : sage),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[day.weekday - 1],
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
