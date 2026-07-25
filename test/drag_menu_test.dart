import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/SpringButton/micro_interactions.dart';
import 'package:playground/SpringButton/src/drag_menu/drag_menu_overlay.dart';

void main() {
  testWidgets('SpringButton dragging works', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpringButton(
            onTap: () => tapped = true,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );

    // Press down
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SpringButton)),
    );
    await tester.pump();

    // Drag
    await gesture.moveBy(const Offset(50, 50));
    await tester.pump();

    // Check if pointer is still considered down in the widget state
    final state = tester.state(find.byType(SpringButton)) as dynamic;
    expect(
      state._pointerDown,
      isTrue,
      reason: 'Pointer should still be down during drag',
    );
    expect(
      state._dragged,
      isTrue,
      reason: 'Widget should recognize it was dragged',
    );

    // Release
    await gesture.up();
    await tester.pump();

    expect(tapped, isFalse, reason: 'Tap should not fire if dragged');
  });

  testWidgets('DragMenu shows overlay on long press', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DragMenu(
            items: [DragMenuItem(label: 'Item 1', onSelected: () {})],
            child: const Text('Target'),
          ),
        ),
      ),
    );

    expect(find.byType(DragMenuOverlay), findsNothing);

    // Long press
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Target')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    tester.allWidgets.forEach(print);
    expect(
      find.byType(DragMenuOverlay),
      findsOneWidget,
      reason: 'Overlay should appear after long press',
    );
  });
}
