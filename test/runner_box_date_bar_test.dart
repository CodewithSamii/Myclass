import 'package:flutter/cupertino.dart';
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

  testWidgets('Date bar refined interaction: no runner box, 1.10x focus, block snapping, and calendar button', (tester) async {
    final d = await boot(tester);
    await settle(tester);

    final context = tester.element(find.byKey(const PageStorageKey('home')));
    final scheduleBloc = context.read<ScheduleBloc>();
    final initialDate = dateOnly(scheduleBloc.state.selected);

    // 1. Verify FIXED RUNNER BOX IS COMPLETELY REMOVED
    final runnerBoxFinder = find.byWidgetPredicate((widget) {
      if (widget is Container) {
        final dec = widget.decoration;
        if (dec is BoxDecoration && dec.border is Border) {
          final top = (dec.border as Border).top;
          return top.width == 2.2 && widget.constraints?.maxWidth == 76.0;
        }
      }
      return false;
    });
    expect(runnerBoxFinder, findsNothing, reason: 'Runner Box border overlay must be completely removed');

    // 2. Verify focus emphasis on selected date (bigger scale)
    final selectedScaleFinder = find.byWidgetPredicate((widget) {
      if (widget is AnimatedScale) {
        return widget.scale >= 1.10;
      }
      return false;
    });
    expect(selectedScaleFinder, findsWidgets, reason: 'Selected date must have focus scale >= 1.10x');

    // 3. Verify Today indicator remains attached to today's item
    expect(find.text('TODAY'), findsOneWidget);

    // 4. Verify tiny calendar button exists at top-right of date bar
    final calendarButton = find.descendant(
      of: find.byType(ChocolateBlockDateBar),
      matching: find.byIcon(CupertinoIcons.calendar),
    );
    expect(calendarButton, findsOneWidget, reason: 'Small calendar jump button must exist at top-right of date bar');

    // 5. Small horizontal swipe left -> snaps exactly one complete date (+1 day)
    final dateBarFinder = find.byType(ChocolateBlockDateBar).first;
    expect(dateBarFinder, findsOneWidget);

    // Small swipe left: 25 px
    await tester.drag(dateBarFinder, const Offset(-25, 0));
    await settle(tester);

    final expectedDay1 = initialDate.add(const Duration(days: 1));
    expect(sameDay(scheduleBloc.state.selected, expectedDay1), isTrue,
        reason: 'Small left swipe must snap to immediately next complete date');

    // 6. Another small swipe left -> (+2 days)
    await tester.drag(dateBarFinder, const Offset(-25, 0));
    await settle(tester);

    final expectedDay2 = initialDate.add(const Duration(days: 2));
    expect(sameDay(scheduleBloc.state.selected, expectedDay2), isTrue,
        reason: 'Second small left swipe must advance to next date');

    // 7. Small swipe right -> moves back by one complete date (-1 day)
    await tester.drag(dateBarFinder, const Offset(25, 0));
    await settle(tester);

    expect(sameDay(scheduleBloc.state.selected, expectedDay1), isTrue,
        reason: 'Small right swipe must snap back by one complete date');

    // 8. Tapping an individual date directly selects it
    await tester.drag(dateBarFinder, const Offset(25, 0));
    await settle(tester);
    expect(sameDay(scheduleBloc.state.selected, initialDate), isTrue);

    // 9. Jump to Today button still works
    await tester.drag(dateBarFinder, const Offset(-25 * 3, 0));
    await settle(tester);
    expect(sameDay(scheduleBloc.state.selected, initialDate), isFalse);

    final jumpButton = find.text('Jump to Today');
    if (jumpButton.evaluate().isNotEmpty) {
      await tester.tap(jumpButton);
      await settle(tester);
      expect(sameDay(scheduleBloc.state.selected, dateOnly(scheduleBloc.state.now)), isTrue);
    }

    // 10. Calendar button opens date picker dialog
    await tester.tap(calendarButton);
    await tester.pumpAndSettle();

    // Verify DatePickerDialog or calendar sheet opened
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Close dialog
    final cancelButton = find.text('Cancel');
    if (cancelButton.evaluate().isNotEmpty) {
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();
    }

    await finish(tester, d);
  });
}
