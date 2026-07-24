import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});

  final GardenStore store;

  @override
  Widget build(BuildContext context) {
    return PagePadding(
      child: ListView(
        children: [
          const SectionEyebrow('Make it yours'),
          Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDDEBDD),
                    child: Text('🌿'),
                  ),
                  title: Text(
                    store.gardenerName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Garden keeper'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editName(context),
                ),
                const Divider(height: 1, indent: 70),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Gentle reminders'),
                  subtitle: const Text('Show encouragement inside the app'),
                  value: store.settings.gentleReminders,
                  onChanged: (value) =>
                      store.updateSettings(gentleReminders: value),
                ),
                const Divider(height: 1, indent: 70),
                SwitchListTile(
                  key: const Key('dark-mode-toggle'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark mode'),
                  subtitle: const Text('Use a cozy evening color palette'),
                  value: store.settings.darkMode,
                  onChanged: (value) => store.updateSettings(darkMode: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Habit library',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Archived habits'),
                  subtitle: Text('${store.archivedHabits.length} saved'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showArchived(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('About', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.favorite_outline),
                  title: Text('Cozy Habit Garden'),
                  subtitle: Text(
                    'Version 1.0.0 · Your data stays on this device',
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.accessibility_new_rounded),
                  title: Text('Designed for gentle progress'),
                  subtitle: Text(
                    'No streak shame, ads, accounts, or social comparison.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset garden and start over'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: store.settings.gardenerName);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your garden name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              store.updateSettings(name: controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _showArchived(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Archived habits',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: store.archivedHabits.isEmpty
                    ? const Center(child: Text('No archived habits yet.'))
                    : ListView(
                        children: store.archivedHabits
                            .map(
                              (habit) => ListTile(
                                leading: Text(
                                  habit.emoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                title: Text(habit.name),
                                subtitle: Text(
                                  '${habit.totalCompletions} completed days',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'restore') {
                                      store.restoreHabit(habit);
                                    }
                                    if (value == 'delete') {
                                      store.deleteHabit(habit);
                                    }
                                    Navigator.pop(context);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'restore',
                                      child: Text('Restore'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete permanently'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset your whole garden?'),
        content: const Text(
          'All habits, history, dew, and discoveries will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset everything'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.resetGarden();
  }
}
