import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/planner/planner_page.dart';
import '../features/admin/admin_page.dart';
import '../features/admin/team_tasks_page.dart';
import '../features/download/download_page.dart';
import '../shared/widgets/app_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);

  ref.listen(authStateProvider, (_, next) {
    authNotifier.value = next.valueOrNull != null;
  });

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/login',
    redirect: (context, state) async {
      final authState = ref.read(authStateProvider);

      // Vital for web: wait for Firebase to load the saved session from IndexedDB
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;

      final isOnLogin = state.matchedLocation == '/login';
      final isOnDownload = state.matchedLocation == '/download';

      // Allow unauthenticated access to login and download pages
      if (!isLoggedIn && !isOnLogin && !isOnDownload) return '/login';

      // If logged in and trying to login, redirect to dashboard.
      // (We intentionally allow logged in users to access /download if they want).
      if (isLoggedIn && isOnLogin) return '/dashboard';

      // Admin guard
      if (state.matchedLocation == '/admin') {
        final role = await ref.read(userRoleProvider.future);
        if (role != 'admin') return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/download', builder: (_, __) => const DownloadPage()),
      ShellRoute(
        builder: (_, __, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(path: '/planner', builder: (_, __) => const PlannerPage()),
          GoRoute(
              path: '/team-tasks', builder: (_, __) => const TeamTasksPage()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
        ],
      ),
    ],
  );
});
