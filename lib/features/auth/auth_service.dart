import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../shared/models/models.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data()?['role'] as String?) ?? 'user';
      }
      return 'user';
    } catch (_) {
      return 'user';
    }
  }

  /// Creates a new user auth account and writes their Firestore profile.
  Future<UserCredential> createUser({
    required String email,
    required String password,
    required String displayName,
    String role = 'user',
  }) async {
    // 1. Create a secondary app to avoid logging out the current admin
    final tempApp = await Firebase.initializeApp(
      name: 'tempApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      // STOP web from overriding the primary session state in IndexedDB
      await tempAuth.setPersistence(Persistence.NONE);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // 2. Write the profile document using the MAIN db instance
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return credential;
    } finally {
      await tempApp.delete();
    }
  }

  Future<void> updateUserProfile(
    String uid, {
    String? displayName,
    String? role,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (role != null) updates['role'] = role;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }
}
