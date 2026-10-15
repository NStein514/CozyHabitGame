import 'package:cozy_habit_garden/garden_store.dart';
import 'package:cozy_habit_garden/screens/garden_screen.dart';
import 'package:cozy_habit_garden/screens/garden_shell.dart';
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
    expect(find.text('Inventory · tap to place'), findsNothing);
    expect(find.byKey(const Key('selected-item-controls')), findsNothing);
    expect(find.byKey(const Key('garden-trash')), findsOneWidget);
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
    expect(find.byKey(const Key('selected-item-controls')), findsNothing);
    expect(find.byKey(const Key('garden-trash')), findsOneWidget);
    await tester.tap(find.byTooltip('Hide editor tray'));
    await tester.pump();
    final item = find.bySemanticsLabel('Mossy stone');
    final image = find.descendant(of: item, matching: find.byType(Image));
    final selectedSize = tester.getSize(image);
    await tester.tapAt(tester.getTopLeft(canvas) + const Offset(30, 70));
    await tester.pumpAndSettle();
    expect(tester.getSize(image), selectedSize);
    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(tester.getSize(image), selectedSize);
    final gesture = await tester.startGesture(tester.getCenter(item));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('garden-trash'))),
    );
    await tester.pump();
    await gesture.up();
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

    expect(find.byKey(const Key('selected-item-controls')), findsNothing);
    expect(find.byKey(const Key('garden-trash')), findsOneWidget);
    final level = tester.getRect(find.text('Garden level ${store.level}'));
    final inventory = tester.getRect(find.byKey(const Key('garden-inventory')));
    final touch = tester.getRect(find.byIcon(Icons.touch_app_outlined));
    expect(level.right, lessThan(inventory.left));
    expect(inventory.right, lessThan(touch.left));
    expect((inventory.center.dy - level.center.dy).abs(), lessThan(1));
    final summary = find.text(
      'Arrange freely — your layout stays where you leave it',
    );
    expect(tester.widget<Text>(summary).overflow, isNot(TextOverflow.ellipsis));
    expect(
      tester.getRect(summary).right,
      lessThan(tester.getRect(find.text('1 placed')).left),
    );
    expect(tester.getRect(find.text('1 placed')).right, lessThanOrEqualTo(320));
    await tester.tap(find.byKey(const Key('garden-inventory')));
    await tester.pump();
    expect(find.text('Inventory · tap to place'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('leaving the garden or backgrounding the app finishes editing', (
    tester,
  ) async {
    final store = GardenStore(persistence: false, seedOnFirstLaunch: false);
    await store.load();
    await tester.pumpWidget(MaterialApp(home: GardenShell(store: store)));
    await tester.tap(find.text('Garden').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('garden-editor-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-Mossy stone')));
    await tester.pump();
    final position = (store.placedItems.single.x, store.placedItems.single.y);
    await tester.tap(find.text('Today').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garden').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit garden'), findsOneWidget);
    expect(find.byKey(const Key('garden-trash')), findsNothing);
    expect(find.text('Inventory · tap to place'), findsNothing);
    expect((store.placedItems.single.x, store.placedItems.single.y), position);
    await tester.tap(find.byKey(const Key('garden-editor-toggle')));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Edit garden'), findsOneWidget);
    expect(find.byKey(const Key('garden-trash')), findsNothing);
    expect(find.text('Inventory · tap to place'), findsNothing);
    expect((store.placedItems.single.x, store.placedItems.single.y), position);
    expect(tester.takeException(), isNull);
  });
}
