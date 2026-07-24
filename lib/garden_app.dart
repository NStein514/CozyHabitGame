import 'package:flutter/material.dart';

import 'garden_store.dart';
import 'screens/garden_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/cozy_theme.dart';

/// Root widget for Cozy Habit Garden.
class CozyGardenApp extends StatefulWidget {
  const CozyGardenApp({super.key, required this.store});

  final GardenStore store;

  @override
  State<CozyGardenApp> createState() => _CozyGardenAppState();
}

class _CozyGardenAppState extends State<CozyGardenApp> {
  @override
  void initState() {
    super.initState();
    widget.store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, child) => MaterialApp(
        title: 'Cozy Habit Garden',
        debugShowCheckedModeBanner: false,
        theme: buildCozyTheme(),
        darkTheme: buildCozyDarkTheme(),
        themeMode: widget.store.settings.darkMode
            ? ThemeMode.dark
            : ThemeMode.light,
        home: !widget.store.loaded
            ? const _SplashScreen()
            : !widget.store.settings.onboardingComplete
            ? OnboardingScreen(store: widget.store)
            : GardenShell(store: widget.store),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌱', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text('Waking up your garden…'),
          ],
        ),
      ),
    );
  }
}
