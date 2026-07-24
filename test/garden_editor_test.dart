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
    await tester.tap(find.byKey(const Key('place-Mossy stone')));
    await tester.pump();
    expect(store.placedItems, hasLength(1));
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
    await tester.tap(find.byTooltip('Rotate Mossy stone'));
    await tester.pump();
    await tester.tap(find.byTooltip('Resize Mossy stone'));
    await tester.pump();
    expect(store.placedItems.single.rotation, greaterThan(0));
    expect(store.placedItems.single.scale, greaterThan(1));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(store.placedItems, isEmpty);
    expect(store.availableCount('Mossy stone'), 1);
  });
}
