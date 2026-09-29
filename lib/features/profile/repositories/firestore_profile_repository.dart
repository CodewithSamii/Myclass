import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models.dart';
import 'profile_repository.dart';

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({
    FirebaseFirestore? firestore,
    required this.preferences,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final SharedPreferences preferences;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> load(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromJson(doc.data()!);
        await preferences.setString('profile_$uid', jsonEncode(profile.toJson()));
        return profile;
      }
    } catch (_) {
      // Network error or offline: fallback to cached local preferences
    }

    final localJson = preferences.getString('profile_$uid');
    if (localJson != null) {
      try {
        return UserProfile.fromJson(
          Map<String, dynamic>.from(jsonDecode(localJson)),
        );
      } catch (_) {}
    }
    return null;
  }

  @override
  Stream<UserProfile?> watch(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        try {
          final profile = UserProfile.fromJson(snap.data()!);
          preferences.setString('profile_$uid', jsonEncode(profile.toJson()));
          return profile;
        } catch (_) {}
      }
      return null;
    });
  }

  @override
  Future<void> save(UserProfile profile, {SectionGrant? grant}) async {
    final data = profile.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (grant != null) {
      data['lastGrant'] = {
        'sectionId': grant.sectionId,
        'role': grant.role.name,
      };
    }

    // Persist locally first for zero-latency UI updates
    await preferences.setString('profile_${profile.uid}', jsonEncode(profile.toJson()));

    try {
      await _users.doc(profile.uid).set(data, SetOptions(merge: true));
    } catch (_) {
      // Firestore offline queue will automatically sync when online
    }
  }
}
