import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myclass/core/clock.dart';
import 'package:myclass/features/schedule/bloc/schedule_bloc.dart';
import 'package:myclass/shared/widgets/chocolate_block_date_bar.dart';
import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  testWidgets('Date-bar: Focus position remains permanently fixed at center while dates scroll through it', (tester) async {
    final d = await boot(tester);
    await settle(tester);

    final context = tester.element(find.byKey(const PageStorageKey('home')));
    final scheduleBloc = context.read<ScheduleBloc>();
    final initialDate = dateOnly(scheduleBloc.state.selected);

    final dateBarFinder = find.byType(ChocolateBlockDateBar).first;
    expect(dateBarFinder, findsOneWidget);

    final barCenter = tester.getCenter(dateBarFinder);

    // 1. Verify NO EXTRA COLOUR at the fixed point: no colored overlay box
    final coloredOverlayFinder = find.descendant(
      of: dateBarFinder,
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          return dec.gradient != null;
        }
        return false;
      }),
    );
    expect(coloredOverlayFinder, findsNothing,
        reason: 'There must be no colored overlay box at the fixed point');

    // 2. Initial state: exactly one date item at the fixed point is noticeably bigger (scale >= 1.15)
    final initialFocusedFinder = find.descendant(
      of: dateBarFinder,
      matching: find.byWidgetPredicate((w) => w is AnimatedScale && w.scale >= 1.15),
    );
    expect(initialFocusedFinder, findsOneWidget);
    final initialFocusedPos = tester.getCenter(initialFocusedFinder);
    expect((initialFocusedPos.dx - barCenter.dx).abs(), lessThan(5.0),
        reason: 'Enlarged date must be aligned with viewport center');

    // 3. Normal swipe: Swipe by 120 px
    await tester.drag(dateBarFinder, const Offset(-120, 0));
    await settle(tester);

    // After scrolling, the enlarged item must STILL be at the exact same screen center position
    final postScrollFocusedFinder = find.descendant(
      of: dateBarFinder,
      matching: find.byWidgetPredicate((w) => w is AnimatedScale && w.scale >= 1.15),
    );
    expect(postScrollFocusedFinder, findsOneWidget);
    final postScrollFocusedPos = tester.getCenter(postScrollFocusedFinder);
    expect((postScrollFocusedPos.dx - barCenter.dx).abs(), lessThan(5.0),
        reason: 'Enlarged focus position must remain permanently fixed at screen center');

    // Verify date changed to the one that moved through the focus position
    expect(sameDay(scheduleBloc.state.selected, initialDate), isFalse);

    // 4. Fast / High-speed horizontal swipe (-400 px)
    final fastSwipeStartDate = scheduleBloc.state.selected;
    await tester.fling(dateBarFinder, const Offset(-400, 0), 1500.0);
    await settle(tester);

    // Even after high-speed swipe, enlarged item must still be at center
    final postFlingFocusedFinder = find.descendant(
      of: dateBarFinder,
      matching: find.byWidgetPredicate((w) => w is AnimatedScale && w.scale >= 1.15),
    );
    expect(postFlingFocusedFinder, findsOneWidget);
    final postFlingFocusedPos = tester.getCenter(postFlingFocusedFinder);
    expect((postFlingFocusedPos.dx - barCenter.dx).abs(), lessThan(5.0),
        reason: 'Enlarged focus position must remain permanently fixed at screen center even after high-speed swipe');

    // And selected date updated to the one settled at center
    expect(sameDay(scheduleBloc.state.selected, fastSwipeStartDate), isFalse);

    // 5. Fast swipe back in opposite direction (+500 px)
    await tester.fling(dateBarFinder, const Offset(500, 0), 1800.0);
    await settle(tester);

    final finalFocusedFinder = find.descendant(
      of: dateBarFinder,
      matching: find.byWidgetPredicate((w) => w is AnimatedScale && w.scale >= 1.15),
    );
    expect(finalFocusedFinder, findsOneWidget);
    final finalFocusedPos = tester.getCenter(finalFocusedFinder);
    expect((finalFocusedPos.dx - barCenter.dx).abs(), lessThan(5.0),
        reason: 'Enlarged focus position permanently fixed at screen center');

    await finish(tester, d);
  });
}
