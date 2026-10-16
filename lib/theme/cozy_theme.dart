import 'package:flutter/material.dart';

const cream = Color(0xFFF1E8D7);
const lightSurface = Color(0xFFFAF4E7);
const ink = Color(0xFF25352E);
const forest = Color(0xFF356859);
const sage = Color(0xFF7EA68B);
const peach = Color(0xFFF2AE86);
const butter = Color(0xFFF6D98B);

Color lightModeText(BuildContext context, [Color darkColor = Colors.white]) =>
    Theme.of(context).brightness == Brightness.light ? ink : darkColor;

Color lightModeFill(BuildContext context, [Color darkColor = forest]) =>
    Theme.of(context).brightness == Brightness.light
    ? const Color(0xFFCDE2CF)
    : darkColor;

ThemeData buildCozyTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: forest,
        brightness: Brightness.light,
        surface: lightSurface,
      ).copyWith(
        onSurface: ink,
        onPrimary: ink,
        onSecondary: ink,
        onTertiary: ink,
        onError: ink,
        onSurfaceVariant: const Color(0xFF536159),
        outlineVariant: const Color(0xFFB7B9A9),
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: cream,
    primaryTextTheme: base.primaryTextTheme.apply(
      bodyColor: ink,
      displayColor: ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: scheme.primaryContainer,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: lightSurface,
      contentTextStyle: TextStyle(color: ink),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: lightSurface),
      textStyle: TextStyle(color: ink),
    ),
    colorScheme: scheme,
    textTheme: base.textTheme
        .apply(bodyColor: ink, displayColor: ink)
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -.8,
          ),
          headlineSmall: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
        )
        .apply(bodyColor: ink, displayColor: ink),
    cardTheme: CardThemeData(
      elevation: 0,
      color: lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFBF2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

ThemeData buildCozyDarkTheme() {
  const night = Color(0xFF17231E);
  const nightSurface = Color(0xFF22322B);
  const moonInk = Color(0xFFF5EFDF);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: sage,
        brightness: Brightness.dark,
        surface: nightSurface,
      ).copyWith(
        primary: const Color(0xFFA8CFB2),
        secondary: const Color(0xFFF0B88F),
        onSurface: moonInk,
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: night,
    colorScheme: scheme,
    textTheme: base.textTheme
        .apply(bodyColor: moonInk, displayColor: moonInk)
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -.8,
          ),
          headlineSmall: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
        ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF293A32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2B3D34),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF202F28),
      indicatorColor: Color(0xFF3C5A4C),
    ),
    dividerColor: Colors.white12,
  );
}
