import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../models.dart';
import '../theme/cozy_theme.dart';

Future<void> showHabitEditor(
  BuildContext context,
  GardenStore store, {
  Habit? habit,
}) async {
  final nameController = TextEditingController(text: habit?.name ?? '');
  var emoji = habit?.emoji ?? '🌱';
  var type = habit?.type ?? HabitType.mind;
  var target = habit?.target ?? 1;
  var days = Set<int>.from(habit?.scheduledWeekdays ?? {1, 2, 3, 4, 5, 6, 7});
  var showValidation = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cream,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final isValid =
            nameController.text.trim().isNotEmpty && days.isNotEmpty;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            6,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit == null ? 'Plant a new habit' : 'Tend your habit',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Keep it kind, clear, and small enough for a busy day.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: habit == null,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 60,
                onChanged: (_) => setSheetState(() {}),
                decoration: InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'Read for 10 minutes',
                  errorText:
                      showValidation && nameController.text.trim().isEmpty
                      ? 'Give this habit a name'
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Symbol',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['🌱', '📖', '💧', '🧘', '👟', '🧺', '💛', '🎨']
                    .map(
                      (option) => ChoiceChip(
                        label: Text(
                          option,
                          style: const TextStyle(fontSize: 20),
                        ),
                        selected: emoji == option,
                        showCheckmark: false,
                        onSelected: (_) => setSheetState(() => emoji = option),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'Kind of care',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: HabitType.values
                    .map(
                      (option) => ChoiceChip(
                        label: Text(option.label),
                        selected: type == option,
                        onSelected: (_) => setSheetState(() => type = option),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily check-ins',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'For habits like water or stretching',
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: target > 1
                        ? () => setSheetState(() => target--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$target',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const Key('habit-target-increase'),
                    onPressed: target < 10
                        ? () => setSheetState(() => target++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Repeat on',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final weekday = index + 1;
                  final selected = days.contains(weekday);
                  return Semantics(
                    label: const [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ][index],
                    selected: selected,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => setSheetState(() {
                        selected ? days.remove(weekday) : days.add(weekday);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 39,
                        height: 39,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? forest : const Color(0xFFE9EDE8),
                        ),
                        child: Text(
                          const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                          style: TextStyle(
                            color: selected ? Colors.white : ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (showValidation && days.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Choose at least one day',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {
                  if (!isValid) {
                    setSheetState(() => showValidation = true);
                    return;
                  }
                  if (habit == null) {
                    store.addHabit(
                      nameController.text,
                      emoji,
                      type,
                      target: target,
                      scheduledWeekdays: days,
                    );
                  } else {
                    store.updateHabit(
                      habit,
                      name: nameController.text,
                      emoji: emoji,
                      type: type,
                      target: target,
                      scheduledWeekdays: days,
                    );
                  }
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: forest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  habit == null ? 'Plant this habit' : 'Save changes',
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  // The bottom-sheet route can still render during its reverse animation after
  // its Future completes. Let the short-lived controller be garbage-collected
  // with the route instead of disposing it while TextField is still detaching.
}
