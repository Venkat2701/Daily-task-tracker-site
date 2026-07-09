import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_service.dart';
import '../shared/models/models.dart';
import '../shared/services/data_service.dart';

// ── Service Providers ────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final dataServiceProvider = Provider<DataService>((ref) => DataService());

// ── Auth State ────────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Resolved user role: 'admin' | 'user' | null (loading/unauthenticated)
final userRoleProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return null;
      return ref.watch(authServiceProvider).getUserRole(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Complete current user model (fetched from Firestore)
final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return null;
      return ref.watch(dataServiceProvider).getUser(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ── Task Data State ────────────────────────────────────────────────────────────

final selectedDateProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
});

/// UID to view as (for admin: can be another user; for users: always their own)
final viewAsUidProvider = StateProvider<String?>((ref) => null);

final allDayDataProvider = StreamProvider.family<Map<String, dynamic>, String>((
  ref,
  uid,
) {
  return ref
      .watch(dataServiceProvider)
      .watchAllDayData(uid)
      .map((data) => data.map((k, v) => MapEntry(k, v as dynamic)));
});

// ── Admin User List ────────────────────────────────────────────────────────────

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(dataServiceProvider).watchAllUsers();
});
