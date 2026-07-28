import 'package:cozy_habit_garden/garden_store.dart';
import 'package:cozy_habit_garden/screens/garden_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('garden editor places and removes an owned decoration', (
    tester,
  ) async {
    final store = GardenStore(persistence: false, seedOnFirstLaunch: false);
    await store.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: store,
            builder: (context, _) => GardenScreen(store: store),
          ),
        ),
      ),
    );

    expect(store.placedItems, isEmpty);
    final canvasSize = tester.getSize(find.byKey(const Key('garden-canvas')));
    await tester.tap(find.byKey(const Key('garden-editor-toggle')));
    await tester.pump();
    expect(tester.getSize(find.byKey(const Key('garden-canvas'))), canvasSize);
    await tester.tap(find.byTooltip('Rename garden'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('garden-name-field')),
      'Moonbeam Haven',
    );
    await tester.tap(find.byKey(const Key('save-garden-name')));
    await tester.pumpAndSettle();
    expect(store.gardenName, 'Moonbeam Haven');
    expect(find.text('Moonbeam Haven'), findsOneWidget);

    await tester.tap(find.byKey(const Key('place-Mossy stone')));
    await tester.pump();
    expect(store.placedItems, hasLength(1));
    expect(find.byKey(const Key('selected-item-controls')), findsOneWidget);
    expect(find.byTooltip('Rotate Mossy stone'), findsNothing);
    final placedPosition = (
      store.placedItems.single.x,
      store.placedItems.single.y,
    );

    await tester.tap(find.byKey(const Key('garden-editor-toggle')));
    await tester.pump();
    expect(tester.getSize(find.byKey(const Key('garden-canvas'))), canvasSize);
    expect((
      store.placedItems.single.x,
      store.placedItems.single.y,
    ), placedPosition);

    await tester.tap(find.byKey(const Key('garden-editor-toggle')));
    await tester.pump();
    await tester.tap(find.byTooltip('Hide editor tray'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Mossy stone'));
    await tester.pump();

    final beforeDrag = store.placedItems.single.x;
    await tester.drag(
      find.byKey(const Key('garden-canvas')),
      const Offset(45, -20),
    );
    await tester.pump();
    expect(store.placedItems.single.x, greaterThan(beforeDrag));

    final canvas = find.byKey(const Key('garden-canvas'));
    final center = tester.getCenter(canvas);
    final firstFinger = await tester.startGesture(
      center + const Offset(-45, -80),
      pointer: 1,
    );
    final secondFinger = await tester.startGesture(
      center + const Offset(45, -80),
      pointer: 2,
    );
    await tester.pump();
    await firstFinger.moveBy(const Offset(-30, 0));
    await secondFinger.moveBy(const Offset(30, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pump();
    expect(store.placedItems.single.scale, greaterThan(1));

    final canvasTopLeft = tester.getTopLeft(canvas);
    final canvasSizeAfterEdit = tester.getSize(canvas);
    await tester.tapAt(
      canvasTopLeft + Offset(55, canvasSizeAfterEdit.height - 70),
    );
    await tester.pump();
    await tester.tap(find.text('Inventory'));
    await tester.pump();
    expect(find.byKey(const Key('selected-item-controls')), findsNothing);

    await tester.tap(find.bySemanticsLabel('Mossy stone'));
    await tester.pump();
    expect(find.byKey(const Key('selected-item-controls')), findsOneWidget);
    await tester.tap(find.byTooltip('Return to inventory'));
    await tester.pump();
    expect(store.placedItems, isEmpty);
    expect(store.availableCount('Mossy stone'), 1);
  });

  testWidgets('garden editor remains usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = GardenStore(persistence: false, seedOnFirstLaunch: false);
    await store.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: store,
            builder: (context, _) => GardenScreen(store: store),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('garden-editor-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-Mossy stone')));
    await tester.pump();

    expect(find.byKey(const Key('selected-item-controls')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
