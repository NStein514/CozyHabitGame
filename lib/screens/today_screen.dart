import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../theme/cozy_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/habit_editor_sheet.dart';
import '../widgets/habit_tile.dart';
import '../widgets/progress_garden.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.store});

  final GardenStore store;

  @override
  Widget build(BuildContext context) {
    final now = store.today;
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final habits = store.todayHabits;
    final allDone = habits.isNotEmpty && store.todayDone == habits.length;

    return PagePadding(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
                        style: const TextStyle(
                          color: forest,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allDone
                            ? 'Your garden is glowing!'
                            : 'Good ${_dayPart(now)}, ${store.gardenerName}',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
                DewPill(value: store.dew),
              ],
            ),
          ),
          if (store.loadError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: MaterialBanner(
                  content: Text(store.loadError!),
                  leading: const Icon(Icons.info_outline),
                  actions: [
                    TextButton(
                      onPressed: store.clearLoadError,
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 22),
              child: ProgressGarden(store: store),
            ),
          ),
          if (store.settings.gentleReminders &&
              habits.isNotEmpty &&
              store.todayDone == 0)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Card(
                  child: ListTile(
                    leading: Text('🍃', style: TextStyle(fontSize: 27)),
                    title: Text(
                      'Start with the easiest one',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('One tiny check-in is enough to begin.'),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  'Today’s care',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Text(
                  '${store.todayDone} of ${habits.length}',
                  style: const TextStyle(
                    color: forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          if (habits.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyHabits(
                message:
                    'Nothing is scheduled today. Enjoy the breathing room.',
              ),
            ),
          SliverList.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) => HabitTile(
              habit: habits[index],
              store: store,
              onEdit: () =>
                  showHabitEditor(context, store, habit: habits[index]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 30),
              child: OutlinedButton.icon(
                onPressed: () => showHabitEditor(context, store),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Plant a new habit'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: sage),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dayPart(DateTime now) {
    final hour = store.nowProvider().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
