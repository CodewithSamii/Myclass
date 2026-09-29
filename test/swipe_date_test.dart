import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myclass/core/clock.dart';
import 'package:myclass/core/format.dart';
import 'package:myclass/features/schedule/bloc/schedule_bloc.dart';
import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  testWidgets('Horizontal swipe on logged-in page navigates dates correctly', (tester) async {
    final d = await boot(tester);
    await settle(tester);

    final context = tester.element(find.byKey(const PageStorageKey('home')));
    final scheduleBloc = context.read<ScheduleBloc>();

    final initialDate = dateOnly(scheduleBloc.state.selected);

    // 1. Swipe Left (Right to Left) -> Next Date (+1 day)
    // Drag horizontally from (300, 300) to (100, 300)
    await tester.dragFrom(const Offset(300, 300), const Offset(-200, 0));
    await settle(tester);

    final nextExpectedDate = DateTime(initialDate.year, initialDate.month, initialDate.day + 1);
    expect(sameDay(scheduleBloc.state.selected, nextExpectedDate), isTrue,
        reason: 'Swiping left should advance to immediately next date');

    // Verify date header or date bar updated
    expect(find.text(sameDay(nextExpectedDate, scheduleBloc.state.now) ? 'Today' : Fmt.fullDate(nextExpectedDate)), findsOneWidget);

    // 2. Swipe Left again -> Next Date (+2 days from initial)
    await tester.dragFrom(const Offset(300, 300), const Offset(-200, 0));
    await settle(tester);

    final dayAfterNext = DateTime(initialDate.year, initialDate.month, initialDate.day + 2);
    expect(sameDay(scheduleBloc.state.selected, dayAfterNext), isTrue,
        reason: 'Second swipe left should advance one more date');

    // 3. Swipe Right (Left to Right) -> Previous Date (-1 day)
    await tester.dragFrom(const Offset(100, 300), const Offset(200, 0));
    await settle(tester);

    expect(sameDay(scheduleBloc.state.selected, nextExpectedDate), isTrue,
        reason: 'Swiping right should move to immediately previous date');

    // 4. Swipe Right again -> Return to initial date
    await tester.dragFrom(const Offset(100, 300), const Offset(200, 0));
    await settle(tester);

    expect(sameDay(scheduleBloc.state.selected, initialDate), isTrue,
        reason: 'Second swipe right should return to initial date');

    // 5. Vertical drag should scroll without changing date
    final beforeVerticalScrollDate = scheduleBloc.state.selected;
    await tester.drag(find.byKey(const PageStorageKey('home')), const Offset(0, -200));
    await settle(tester);

    expect(sameDay(scheduleBloc.state.selected, beforeVerticalScrollDate), isTrue,
        reason: 'Vertical scrolling must NOT change selected date');

    // 6. Existing Date Bar tap interaction still works and updates selection
    await tester.drag(find.byKey(const PageStorageKey('home')), const Offset(0, 200));
    await settle(tester);

    final targetTapDay = DateTime(initialDate.year, initialDate.month, initialDate.day + 3);
    final tapTargetText = '${targetTapDay.day} ${Fmt.month(targetTapDay).substring(0, 3)}';
    
    if (find.text(tapTargetText).evaluate().isNotEmpty) {
      await tester.tap(find.text(tapTargetText).first);
      await settle(tester);

      expect(sameDay(scheduleBloc.state.selected, targetTapDay), isTrue,
          reason: 'Tapping date on date bar must still select the tapped date');

      // Swipe after tap should move from the newly tapped date
      await tester.dragFrom(const Offset(300, 300), const Offset(-200, 0));
      await settle(tester);

      final afterTapNext = DateTime(targetTapDay.year, targetTapDay.month, targetTapDay.day + 1);
      expect(sameDay(scheduleBloc.state.selected, afterTapNext), isTrue,
          reason: 'Swipe after date tap should advance from newly selected date');
    }

    await finish(tester, d);
  });
}
