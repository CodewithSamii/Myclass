import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.hits = const [],
    this.phase = LoadPhase.initial,
  });
  final String query;
  final List<SearchHit> hits;
  final LoadPhase phase;
  @override
  List<Object?> get props => [query, hits, phase];
}

sealed class SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  SearchQueryChanged(this.query);
  final String query;
}

class SearchResolved extends SearchEvent {
  SearchResolved(this.query, this.hits, this.phase);
  final String query;
  final List<SearchHit> hits;
  final LoadPhase phase;
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this.repository, this.uid, this.section)
    : super(const SearchState()) {
    on<SearchQueryChanged>((e, emit) {
      _timer?.cancel();
      final query = e.query.trim();
      emit(
        SearchState(
          query: query,
          phase: query.isEmpty ? LoadPhase.initial : LoadPhase.loading,
        ),
      );
      if (query.isEmpty) return;
      _timer = Timer(const Duration(milliseconds: 240), () async {
        try {
          final hits = await repository.search(
            query,
            uid: uid,
            sectionId: section,
          );
          if (!isClosed) {
            add(
              SearchResolved(
                query,
                hits,
                hits.isEmpty ? LoadPhase.empty : LoadPhase.loaded,
              ),
            );
          }
        } catch (_) {
          if (!isClosed) add(SearchResolved(query, [], LoadPhase.error));
        }
      });
    });
    on<SearchResolved>((e, emit) {
      if (e.query == state.query) {
        emit(SearchState(query: e.query, hits: e.hits, phase: e.phase));
      }
    });
  }
  final SearchRepository repository;
  final String uid, section;
  Timer? _timer;
  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
