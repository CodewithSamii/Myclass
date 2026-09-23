import 'package:flutter_bloc/flutter_bloc.dart';

/// Serializes mutations so rapid taps have deterministic outcomes.
EventTransformer<E> sequential<E>() =>
    (events, mapper) => events.asyncExpand(mapper);
