import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../models.dart';
import '../theme/cozy_theme.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.store,
    this.onEdit,
  });

  final Habit habit;
  final GardenStore store;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final count = habit.countOn(store.today);
    final completed = habit.completedOn(store.today);
    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmArchive(context),
      onDismissed: (_) {
        store.archiveHabit(habit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${habit.name} was moved to archived habits.'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: butter,
              onPressed: () => store.restoreHabit(habit),
            ),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFE49B8B),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _advance(context, completed),
          onLongPress: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _HabitEmoji(emoji: habit.emoji, completed: completed),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: completed
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: .55)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle(count),
                        style: TextStyle(
                          color: completed
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (habit.target > 1)
                  _CountBadge(
                    count: count,
                    target: habit.target,
                    completed: completed,
                  )
                else
                  _CheckBadge(completed: completed),
                PopupMenuButton<String>(
                  tooltip: 'Habit options',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'undo') store.decrementHabit(habit);
                    if (value == 'archive') store.archiveHabit(habit);
                    if (value == 'delete') _deleteHabit(context);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit habit'),
                    ),
                    if (count > 0)
                      const PopupMenuItem(
                        value: 'undo',
                        child: Text('Undo one check-in'),
                      ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive habit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete habit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(int count) {
    final streak = habit.streakAt(store.today);
    if (habit.target > 1 && count < habit.target) {
      return '$count of ${habit.target} today';
    }
    return streak > 0 ? '🔥 $streak day streak' : 'A fresh beginning';
  }

  void _advance(BuildContext context, bool completed) {
    if (completed) {
      store.decrementHabit(habit);
      return;
    }
    store.incrementHabit(habit);
    final nowComplete = habit.completedOn(store.today);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowComplete
              ? 'Habit tended! +${GardenStore.actionDewReward} dew'
              : '${habit.countOn(store.today)} of ${habit.target} check-ins',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: forest,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteHabit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this habit?'),
        content: Text(
          '“${habit.name}” and its history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete habit'),
          ),
        ],
      ),
    );
    if (confirmed == true) store.deleteHabit(habit);
  }

  Future<bool> _confirmArchive(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Archive this habit?'),
            content: const Text(
              'Its history stays safe and you can restore it later.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep it'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Archive'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _HabitEmoji extends StatelessWidget {
  const _HabitEmoji({required this.emoji, required this.completed});
  final String emoji;
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: completed
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(emoji, style: const TextStyle(fontSize: 25)),
  );
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.completed});
  final bool completed;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: 31,
    height: 31,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: completed
          ? Theme.of(context).colorScheme.primary
          : Colors.transparent,
      border: Border.all(
        color: completed
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
        width: 2,
      ),
    ),
    child: completed
        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
        : null,
  );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.target,
    required this.completed,
  });
  final int count;
  final int target;
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: completed
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$count/$target',
      style: TextStyle(
        color: completed
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    ),
  );
}

class EmptyHabits extends StatelessWidget {
  const EmptyHabits({
    super.key,
    this.message = 'Plant your first habit below.',
  });
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🪴', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          const Text(
            'Your garden has room to grow',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
