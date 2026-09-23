import 'package:equatable/equatable.dart';

enum LoadPhase {
  initial,
  loading,
  loaded,
  updated,
  offline,
  error,
  permissionDenied,
  notFound,
  empty,
}

class AppFailure implements Exception {
  const AppFailure(this.message, {this.phase = LoadPhase.error});
  final String message;
  final LoadPhase phase;
  @override
  String toString() => message;
}

class Feed<T> extends Equatable {
  const Feed(
    this.items, {
    this.offline = false,
    this.stale = false,
    this.unavailable = false,
    required this.updatedAt,
  });
  final List<T> items;
  final bool offline, stale, unavailable;
  final DateTime updatedAt;
  @override
  List<Object?> get props => [items, offline, stale, unavailable, updatedAt];
}
