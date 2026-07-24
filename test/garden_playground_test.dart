import 'package:cozy_habit_garden/debug/garden_playground.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('single playground can simulate progress across days', (
    tester,
  ) async {
    await tester.pumpWidget(const GardenPlayground());
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Rowan'), findsOneWidget);
    expect(find.text('0 of 3'), findsOneWidget);

    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(find.text('Garden test controls'), findsOneWidget);

    await tester.tap(find.text('Complete today’s habits'));
    await tester.pumpAndSettle();
    expect(find.text('3 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('July 21, 2026'), findsOneWidget);

    await tester.tap(find.text('Simulate a healthy week'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Garden test controls'), findsOneWidget);
  });
}
