import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';

/// Top-level responsive shell with collapsible sidebar.
class AppScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;

    if (isMobile) {
      return _MobileScaffold(child: widget.child);
    }

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            width: _sidebarCollapsed ? 68 : 260,
            child: AppSidebar(
              collapsed: _sidebarCollapsed || isTablet,
              onToggle: () =>
                  setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            ),
          ),
          Expanded(child: ClipRect(child: widget.child)),
        ],
      ),
    );
  }
}

class _MobileScaffold extends ConsumerWidget {
  final Widget child;
  const _MobileScaffold({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      drawer: Drawer(
        backgroundColor: AppTheme.navy,
        child: const AppSidebar(collapsed: false, onToggle: null),
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            _MiniLogo(),
            const SizedBox(width: 10),
            const Text(
              'Pro-Inspector',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

class _MiniLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.task_alt, color: Colors.white, size: 24);
  }
}

/// ── Sidebar Widget ─────────────────────────────────────────────────────────

class AppSidebar extends ConsumerWidget {
  final bool collapsed;
  final VoidCallback? onToggle;
  const AppSidebar({super.key, required this.collapsed, this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    final userModel = ref.watch(currentUserModelProvider).valueOrNull;
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      color: AppTheme.navy,
      child: Column(
        children: [
          // Brand header
          Padding(
            padding: EdgeInsets.fromLTRB(
              collapsed ? 12 : 20,
              24,
              collapsed ? 8 : 12,
              16,
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Image.asset(
                  'assets/images/mayvel_logo.png',
                  height: 51,
                  errorBuilder: (_, __, ___) => Container(
                    width: 51,
                    height: 51,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                if (!collapsed)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pro-Inspector',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Daily Tracker',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                if (!collapsed && onToggle != null)
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                  )
                else if (collapsed && onToggle != null)
                  GestureDetector(
                    onTap: onToggle,
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // Nav items
          _NavItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            route: '/dashboard',
            collapsed: collapsed,
            active: location.startsWith('/dashboard'),
          ),
          _NavItem(
            icon: Icons.task_alt_rounded,
            label: 'Task Planner',
            route: '/planner',
            collapsed: collapsed,
            active: location.startsWith('/planner'),
          ),
          if (role == 'admin') ...[
            _NavItem(
              icon: Icons.groups_rounded,
              label: 'Team\'s Tasks',
              route: '/team-tasks',
              collapsed: collapsed,
              active: location.startsWith('/team-tasks'),
            ),
            _NavItem(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Admin',
              route: '/admin',
              collapsed: collapsed,
              active: location.startsWith('/admin'),
            ),
          ],

          const Spacer(),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // Firebase status dot
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x8810B981), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Connected · Firestore',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),

          // User chip + logout
          Padding(
            padding: EdgeInsets.fromLTRB(
              collapsed ? 8 : 12,
              8,
              collapsed ? 8 : 12,
              20,
            ),
            child: collapsed
                ? IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => _logout(context, ref),
                    tooltip: 'Sign out',
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.sidebarActive,
                        child: Text(
                          (userModel?.displayName.isNotEmpty == true
                                  ? userModel!.displayName[0]
                                  : '?')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userModel?.displayName ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (role == 'admin')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white38,
                          size: 18,
                        ),
                        onPressed: () => _logout(context, ref),
                        tooltip: 'Sign out',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) context.go('/login');
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool collapsed;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.collapsed,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 8 : 12,
        vertical: 2,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: active ? AppTheme.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: active
              ? const Border(
                  left: BorderSide(color: AppTheme.primary, width: 3),
                )
              : null,
        ),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? Colors.white : Colors.white54,
                  size: 20,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white60,
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
