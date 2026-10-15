import 'dart:ui' as ui;
import 'package:cozy_habit_garden/widgets/vine_navigation_bar.dart';
import 'package:cozy_habit_garden/theme/cozy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  VineGrowthPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.byKey(const Key('navigation-growing-vine')),
              )
              .painter!
          as VineGrowthPainter;

  Future<void> loadArtwork(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (var i = 0; i < 200 && painter(tester).runner == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        // Image decoding requests a widget rebuild, pumped below.
        if (tester.binding.hasScheduledFrame) break;
      }
    });
    await tester.pump();
    // Wait for native image decoding without advancing animation time.
    for (var i = 0; i < 100 && painter(tester).runner == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(painter(tester).runner, isNotNull);
    expect(painter(tester).frame, isNotNull);
  }

  Future<void> mount(
    WidgetTester tester, {
    bool dark = false,
    bool reduce = false,
  }) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? buildCozyDarkTheme() : buildCozyTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: child!,
        ),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: VineNavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (value) =>
                  setState(() => selected = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.check_circle_outline),
                  label: 'Today',
                ),
                NavigationDestination(
                  icon: Icon(Icons.eco_outlined),
                  label: 'Garden',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome),
                  label: 'Discover',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart),
                  label: 'Journey',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await loadArtwork(tester);
  }

  for (final dark in [false, true]) {
    testWidgets(
      'continuous vine travels from right screen edge then curls around destination ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 150);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester, dark: dark);
        await tester.pump(const Duration(milliseconds: 180));
        expect(painter(tester).progress, inExclusiveRange(0, .58));
        await tester.pumpAndSettle();
        expect(painter(tester).selectedIndex, 0);
        expect(painter(tester).progress, 1);
        await tester.tap(find.text('Settings'));
        await tester.pump();
        expect(painter(tester).selectedIndex, 4);
        expect(painter(tester).progress, 0);
        await tester.pump(const Duration(milliseconds: 450));
        expect(painter(tester).progress, inExclusiveRange(.58, 1));
        await tester.tap(find.text('Garden'));
        await tester.pump();
        expect(painter(tester).progress, 0);
        await tester.pumpAndSettle();
        expect(painter(tester).selectedIndex, 1);
        expect(painter(tester).progress, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reduced motion displays entire connected vine immediately', (
    tester,
  ) async {
    await mount(tester, reduce: true);
    expect(painter(tester).progress, 1);
    await tester.tap(find.text('Journey'));
    await tester.pump();
    expect(painter(tester).selectedIndex, 3);
    expect(painter(tester).progress, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });
  testWidgets('branch enters on the right and tapers toward that edge', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final sourceRecorder = ui.PictureRecorder();
      Canvas(sourceRecorder).drawRect(
        const Rect.fromLTWH(0, 0, 10, 10),
        Paint()..color = Colors.green,
      );
      final sourcePicture = sourceRecorder.endRecording();
      final source = await sourcePicture.toImage(10, 10);
      sourcePicture.dispose();
      Future<int> alphaAt(double progress, int x, int y) async {
        final recorder = ui.PictureRecorder();
        VineGrowthPainter(
          runner: source,
          frame: source,
          progress: progress,
          selectedIndex: 0,
          count: 5,
          direction: TextDirection.ltr,
        ).paint(Canvas(recorder), const Size(400, 49));
        final picture = recorder.endRecording();
        final image = await picture.toImage(400, 49);
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final alpha = bytes!.getUint8((y * 400 + x) * 4 + 3);
        image.dispose();
        picture.dispose();
        return alpha;
      }

      expect(await alphaAt(.12, 395, 10), greaterThan(0));
      expect(await alphaAt(.12, 80, 10), 0);
      expect(await alphaAt(1, 80, 20), greaterThan(0));
      expect(await alphaAt(1, 395, 20), 0);
      source.dispose();
    });
  });
}
