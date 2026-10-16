import '../widgets/garden_icon.dart';
import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../models.dart';
import '../theme/cozy_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.store});

  final GardenStore store;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      28,
      (index) => store.today.subtract(Duration(days: 27 - index)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Care history'), backgroundColor: cream),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Last 28 days',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Each leaf is a day you tended at least one scheduled habit.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final due = store.habitsFor(day);
                  final done = due
                      .where((habit) => habit.completedOn(day))
                      .length;
                  final ratio = due.isEmpty ? 0.0 : done / due.length;
                  return Tooltip(
                    message: '${day.month}/${day.day}: $done of ${due.length}',
                    child: Semantics(
                      label:
                          '${day.month}/${day.day}, $done of ${due.length} habits complete',
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ratio == 0
                              ? const Color(0xFFE9EDE8)
                              : Color.lerp(
                                  const Color(0xFFCDE2CF),
                                  lightModeFill(context),
                                  ratio,
                                ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: ratio > 0
                            ? const GardenIcon('💛', size: 18)
                            : Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: ink.withValues(alpha: .65),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Habit insights',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          ...store.activeHabits.map(
            (habit) => _HabitInsight(habit: habit, store: store),
          ),
        ],
      ),
    );
  }
}

class _HabitInsight extends StatelessWidget {
  const _HabitInsight({required this.habit, required this.store});
  final Habit habit;
  final GardenStore store;

  @override
  Widget build(BuildContext context) {
    final rate = habit.completionRate(store.today);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GardenIcon(habit.emoji, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 7,
                      color: sage,
                      backgroundColor: const Color(0xFFE6ECE7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(rate * 100).round()}%',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: forest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
