import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/models.dart';

class DataService {
  final FirebaseFirestore _db;

  DataService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _taskDataCol(String uid) =>
      _db.collection('users').doc(uid).collection('dailyData');

  // ── Task Data ──────────────────────────────────────────────────────────────

  /// Stream of all daily data for a user (real-time).
  Stream<Map<String, DayData>> watchAllDayData(String uid) {
    return _taskDataCol(uid).snapshots().map((snap) {
      final map = <String, DayData>{};
      for (final doc in snap.docs) {
        map[doc.id] = DayData.fromMap(doc.data());
      }
      return map;
    });
  }

  /// Stream of a single day's data (real-time).
  Stream<DayData> watchDayData(String uid, String dateStr) {
    return _taskDataCol(
      uid,
    ).doc(dateStr).snapshots().map((doc) => DayData.fromMap(doc.data()));
  }

  /// Get a single day's data once.
  Future<DayData> getDayData(String uid, String dateStr) async {
    final doc = await _taskDataCol(uid).doc(dateStr).get();
    return DayData.fromMap(doc.data());
  }

  /// Save a day's full data (upsert).
  Future<void> saveDayData(String uid, String dateStr, DayData data) async {
    await _taskDataCol(
      uid,
    ).doc(dateStr).set(data.toMap(), SetOptions(merge: false));
  }

  // ── User Management ────────────────────────────────────────────────────────

  /// Stream of all users (admin only).
  Stream<List<UserModel>> watchAllUsers() {
    return _db.collection('users').snapshots().map((snap) {
      return snap.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    });
  }

  /// Get a single user's profile.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  /// Write / update a user profile document.
  Future<void> saveUserProfile(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }
}
