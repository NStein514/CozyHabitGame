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
      for (var i = 0; i < 200 && painter(tester).artwork == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        // Image decoding requests a widget rebuild, pumped below.
        if (tester.binding.hasScheduledFrame) break;
      }
    });
    await tester.pump();
    // Wait for native image decoding without advancing animation time.
    for (var i = 0; i < 100 && painter(tester).artwork == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(painter(tester).artwork, isNotNull);
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
      'vine extends its rooted strands and wilts back without restarting ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 150);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester, dark: dark);
        await tester.pump(const Duration(milliseconds: 180));
        expect(painter(tester).scene.extent, inExclusiveRange(-.08, .1));
        await tester.pumpAndSettle();
        expect(painter(tester).scene.extent, .1);
        expect(painter(tester).scene.crowns.single.center, .1);
        await tester.tap(find.text('Settings'));
        await tester.pump();
        expect(painter(tester).scene.extent, .1);
        expect(painter(tester).scene.crowns.single.center, .1);
        await tester.pump(const Duration(milliseconds: 350));
        final beforeReverse = painter(tester).scene.extent;
        expect(beforeReverse, inExclusiveRange(.3, .9));
        await tester.tap(find.text('Garden'));
        await tester.pump();
        expect(painter(tester).scene.extent, beforeReverse);
        await tester.pump(const Duration(milliseconds: 180));
        expect(painter(tester).scene.extent, lessThan(beforeReverse));
        expect(painter(tester).retreat, greaterThan(0));
        expect(
          painter(tester).scene.crowns.any((crown) => crown.wilt > 0),
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(painter(tester).scene.extent, .3);
        expect(painter(tester).scene.crowns.map((c) => c.center), [.1, .3]);
        expect(painter(tester).scene.crowns.first.tightness, 1);
        expect(painter(tester).scene.crowns.last.tightness, 0);
        expect(painter(tester).scene.crowns.last.opacity, 1);
        expect(painter(tester).scene.crowns.last.wilt, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reduced motion immediately selects the new rooted extent', (
    tester,
  ) async {
    await mount(tester, reduce: true);
    expect(painter(tester).scene.extent, .1);
    await tester.tap(find.text('Journey'));
    await tester.pump();
    expect(painter(tester).scene.extent, .7);
    expect(painter(tester).scene.crowns.map((c) => c.center), [.1, .3, .5, .7]);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('woven strands start on the left and stop at the active crown', (
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
      Future<int> alphaAt(double target, int x, int y) async {
        final recorder = ui.PictureRecorder();
        VineGrowthPainter(
          artwork: source,
          scene: VineScene(
            extent: target,
            crowns: [VineCrown(center: target)],
          ),
          target: target,
          retreat: 0,
          count: 5,
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

      expect(await alphaAt(.3, 0, 25), greaterThan(0));
      expect(await alphaAt(.9, 0, 10), greaterThan(0));
      expect(await alphaAt(.9, 280, 25), greaterThan(0));
      expect(await alphaAt(.3, 120, 25), greaterThan(0));
      expect(await alphaAt(.3, 165, 10), 0);
      expect(await alphaAt(.3, 395, 10), 0);
      expect(await alphaAt(.7, 0, 16), greaterThan(0));
      expect(await alphaAt(.7, 325, 10), 0);
      source.dispose();
    });
  });
  testWidgets(
    'Discover keeps Today and Garden constricted while its own frame stays open',
    (tester) async {
      await mount(tester, reduce: true);
      await tester.tap(find.text('Discover'));
      await tester.pump();
      final crowns = painter(tester).scene.crowns;
      expect(crowns.map((c) => c.center), [.1, .3, .5]);
      expect(crowns.map((c) => c.tightness), [1, 1, 0]);
      expect(
        crowns.every((c) => c.growth == 1 && c.opacity == 1 && c.wilt == 0),
        isTrue,
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets('wilting branches blacken and shed visible fragments', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 10, 10),
        Paint()..color = Colors.green,
      );
      final sourcePicture = recorder.endRecording();
      final source = await sourcePicture.toImage(10, 10);
      sourcePicture.dispose();
      Future<List<int>> render(double wilt, double opacity) async {
        final rec = ui.PictureRecorder();
        VineGrowthPainter(
          artwork: source,
          scene: VineScene(
            extent: .5,
            crowns: [VineCrown(center: .5, wilt: wilt, opacity: opacity)],
          ),
          target: 0,
          retreat: 0,
          count: 5,
        ).paint(Canvas(rec), const Size(400, 49));
        final pic = rec.endRecording();
        final image = await pic.toImage(400, 49);
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final result = bytes!.buffer.asUint8List().toList();
        image.dispose();
        pic.dispose();
        return result;
      }

      final living = await render(0, 1);
      final burned = await render(.5, 1);
      final center = (28 * 400 + 200) * 4;
      expect(living[center + 1], greaterThan(100));
      expect(burned[center + 1], lessThan(10));
      final ashOnly = await render(.6, 0);
      expect(
        [
          for (var y = 0; y < 49; y++)
            for (var x = 170; x < 230; x++) ashOnly[(y * 400 + x) * 4 + 3],
        ].any((alpha) => alpha > 0),
        isTrue,
      );
      final finished = await render(1, 0);
      expect(
        [
          for (var y = 0; y < 49; y++)
            for (var x = 170; x < 230; x++) finished[(y * 400 + x) * 4 + 3],
        ].every((alpha) => alpha == 0),
        isTrue,
      );
      source.dispose();
    });
  });
}
