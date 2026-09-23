import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';
import '../core/repositories.dart';
import 'mock_store.dart';

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this.store, this.preferences);
  final MockStore store;
  final SharedPreferences preferences;
  @override
  Future<UserProfile?> load(String uid) async {
    await store.delay();
    if (store.profile != null) return store.profile;
    final raw = preferences.getString('myclass.profile.$uid') ??
        preferences.getString('aula.profile.$uid');
    if (raw != null) {
      try {
        store.profile = UserProfile.fromJson(jsonDecode(raw));
      } catch (_) {
        await preferences.remove('myclass.profile.$uid');
        await preferences.remove('aula.profile.$uid');
      }
    }
    return store.profile;
  }

  @override
  Stream<UserProfile?> watch(String uid) =>
      store.watch(() => store.profile?.uid == uid ? store.profile : null);
  @override
  Future<void> save(UserProfile profile, {SectionGrant? grant}) async {
    await store.checkWrite();
    store.profile = profile;
    await preferences.setString(
      'myclass.profile.${profile.uid}',
      jsonEncode(profile.toJson()),
    );
    store.notify();
  }
}

class MockNotesRepository implements NotesRepository {
  MockNotesRepository(this.store);
  final MockStore store;
  @override
  Stream<List<PersonalNote>> watchNotes(String uid) => store.watch(
    () => List.unmodifiable(
      store.notes.putIfAbsent(
        uid,
        () => [
          PersonalNote(
            id: 'n1',
            uid: uid,
            text: 'Ask about the project evaluation criteria.',
            updatedAt: DateTime(2026, 9, 20),
            remindAt: DateTime(2026, 9, 22, 10),
          ),
          PersonalNote(
            id: 'n2',
            uid: uid,
            text: 'Review the subnetting example from the last lab.',
            eventId: 'bsc-cse-64-I-network-viva',
            updatedAt: DateTime(2026, 9, 21),
          ),
        ],
      ),
    ),
  );
  @override
  Future<void> save(PersonalNote note) async {
    await store.checkWrite();
    if (store.profile?.uid != note.uid) {
      throw const AppFailure(
        'These notes belong to a different account.',
        phase: LoadPhase.permissionDenied,
      );
    }
    final list = store.notes.putIfAbsent(note.uid, () => []);
    final i = list.indexWhere((n) => n.id == note.id);
    if (i < 0) {
      list.insert(0, note);
    } else {
      list[i] = note;
    }
    store.notify();
  }

  @override
  Future<void> delete(String uid, String id) async {
    await store.checkWrite();
    if (store.profile?.uid != uid) {
      throw const AppFailure(
        'You do not have access to this note.',
        phase: LoadPhase.permissionDenied,
      );
    }
    store.notes[uid]?.removeWhere((n) => n.id == id);
    store.notify();
  }
}

class MockProgressRepository implements ProgressRepository {
  MockProgressRepository(this.store);
  final MockStore store;
  @override
  Stream<List<PersonalProgress>> watch(String uid) => store.watch(
    () => List.unmodifiable(store.progress.putIfAbsent(uid, () => [])),
  );
  @override
  Future<void> save(String uid, PersonalProgress progress) async {
    await store.checkWrite();
    if (store.profile?.uid != uid) {
      throw const AppFailure(
        'Sign in again to save your progress.',
        phase: LoadPhase.permissionDenied,
      );
    }
    final list = store.progress.putIfAbsent(uid, () => []);
    final i = list.indexWhere((p) => p.eventId == progress.eventId);
    if (i < 0) {
      list.add(progress);
    } else {
      list[i] = progress;
    }
    store.notify();
  }
}
