import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../widgets/vine_navigation_bar.dart';
import 'collection_screen.dart';
import 'garden_screen.dart';
import 'journey_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

/// Main navigation shell for the four primary product areas.
class GardenShell extends StatefulWidget {
  const GardenShell({super.key, required this.store});

  final GardenStore store;

  @override
  State<GardenShell> createState() => _GardenShellState();
}

class _GardenShellState extends State<GardenShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(store: widget.store),
      GardenScreen(store: widget.store, active: _selectedIndex == 1),
      CollectionScreen(store: widget.store),
      JourneyScreen(store: widget.store),
      SettingsScreen(store: widget.store),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: VineNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) =>
            setState(() => _selectedIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.checkmark_alt_circle),
            selectedIcon: Icon(CupertinoIcons.checkmark_alt_circle_fill),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.leaf_arrow_circlepath),
            selectedIcon: Icon(CupertinoIcons.leaf_arrow_circlepath),
            label: 'Garden',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.sparkles),
            selectedIcon: Icon(CupertinoIcons.sparkles),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.chart_bar),
            selectedIcon: Icon(CupertinoIcons.chart_bar_fill),
            label: 'Journey',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.gear),
            selectedIcon: Icon(CupertinoIcons.gear_solid),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
