import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'clock.dart';

/// Reactive clock presentation state, independent from the preview controls.
class ClockCubit extends Cubit<DateTime> {
  ClockCubit(AppClock clock) : super(clock.now) {
    _subscription = clock.ticks.listen(emit);
  }
  late final StreamSubscription<DateTime> _subscription;
  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

class SystemClock implements AppClock {
  @override
  DateTime get now => DateTime.now();
  @override
  Stream<DateTime> get ticks =>
      Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
}
