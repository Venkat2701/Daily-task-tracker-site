import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../features/auth/auth_service.dart';
import '../../shared/widgets/toast_widget.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allUsers) {
        final users =
            allUsers.where((u) => u.email != 'admin@dailytracker.com').toList();
        return _AdminContent(users: users);
      },
    );
  }
}

class _AdminContent extends ConsumerWidget {
  final List<UserModel> users;
  const _AdminContent({required this.users});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleFilter = ValueNotifier<String>('all');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Panel',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage team members and roles.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.inkSoft),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context, ref),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add User'),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          // Stats row
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _StatCard(
                label: 'Total Users',
                value: '${users.length}',
                icon: Icons.people,
                color: AppTheme.primary,
              ),
              _StatCard(
                label: 'Admins',
                value: '${users.where((u) => u.isAdmin).length}',
                icon: Icons.admin_panel_settings,
                color: AppTheme.doFirst,
              ),
              _StatCard(
                label: 'Regular Users',
                value: '${users.where((u) => !u.isAdmin).length}',
                icon: Icons.person,
                color: AppTheme.schedule,
              ),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 20),

          // Users table
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'TEAM MEMBERS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.12,
                          color: AppTheme.inkSoft,
                        ),
                  ),
                ),
                const Divider(height: 1),
                ...users.asMap().entries.map((entry) {
                  final i = entry.key;
                  final user = entry.value;
                  return Container(
                    decoration: BoxDecoration(
                      color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
                      border: const Border(
                        bottom: BorderSide(color: AppTheme.line),
                      ),
                    ),
                    child: _UserRow(
                      user: user,
                      onEdit: () => _showEditUserDialog(context, ref, user),
                      onReset: () => _resetPassword(context, ref, user),
                      onToggleRole: () => _toggleRole(context, ref, user),
                    ),
                  );
                }),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'user';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add New User'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (!v!.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) =>
                        (v!.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(
                        value: 'user',
                        child: Text('Regular User'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setState(() => selectedRole = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref.read(authServiceProvider).createUser(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text,
                        displayName: nameCtrl.text.trim(),
                        role: selectedRole,
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx, true);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx, false);
                  }
                  if (context.mounted) {
                    ToastWidget.show(context, 'Error: $e', error: true);
                  }
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      ToastWidget.show(context, 'User created successfully!');
    }
  }

  Future<void> _showEditUserDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final nameCtrl = TextEditingController(text: user.displayName);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit User'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 340,
            child: TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display Name'),
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref.read(authServiceProvider).updateUserProfile(
                      user.uid,
                      displayName: nameCtrl.text.trim(),
                    );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx, true);
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx, false);
                }
                if (context.mounted) {
                  ToastWidget.show(context, 'Error: $e', error: true);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      ToastWidget.show(context, 'Profile updated!');
    }
  }

  Future<void> _resetPassword(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send a password reset email to ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await ref.read(authServiceProvider).sendPasswordReset(user.email);
        if (context.mounted)
          ToastWidget.show(context, 'Reset email sent to ${user.email}');
      } catch (e) {
        if (context.mounted)
          ToastWidget.show(context, 'Error: $e', error: true);
      }
    }
  }

  Future<void> _toggleRole(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final newRole = user.isAdmin ? 'user' : 'admin';
    final label = newRole == 'admin' ? 'promote to Admin' : 'demote to User';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Change Role'),
        content: Text(
          'Are you sure you want to $label for ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await ref
            .read(authServiceProvider)
            .updateUserProfile(user.uid, role: newRole);
        if (context.mounted)
          ToastWidget.show(context, 'Role updated to $newRole');
      } catch (e) {
        if (context.mounted)
          ToastWidget.show(context, 'Error: $e', error: true);
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit, onReset, onToggleRole;

  const _UserRow({
    required this.user,
    required this.onEdit,
    required this.onReset,
    required this.onToggleRole,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 700;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                user.isAdmin ? AppTheme.primary : AppTheme.navyLight,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: user.isAdmin
                            ? AppTheme.primaryBg
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: user.isAdmin
                              ? AppTheme.primary
                              : AppTheme.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.inkSoft),
                ),
              ],
            ),
          ),
          if (isWide) ...[
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.lock_reset, size: 14),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onToggleRole,
              icon: Icon(
                user.isAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                size: 14,
              ),
              label: Text(user.isAdmin ? 'Demote' : 'Promote'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                foregroundColor:
                    user.isAdmin ? AppTheme.doFirst : AppTheme.schedule,
                side: BorderSide(
                  color: user.isAdmin ? AppTheme.doFirst : AppTheme.schedule,
                ),
              ),
            ),
          ] else
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'reset') onReset();
                if (v == 'role') onToggleRole();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Name')),
                const PopupMenuItem(
                  value: 'reset',
                  child: Text('Reset Password'),
                ),
                const PopupMenuItem(value: 'role', child: Text('Toggle Role')),
              ],
            ),
        ],
      ),
    );
  }
}
