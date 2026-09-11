import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers([String? search]) async {
    setState(() => _isLoading = true);
    try {
      final u = await ApiService().getUsers(search: search);
      setState(() {
        _users = u;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showChangeRoleDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Роль для @${user.username}'),
        children: UserRole.values.map((role) {
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().updateUserRole(user.id, role.toServerString());
                _loadUsers(_searchController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppTheme.success, content: Text('Роль изменена на ${role.displayName}')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
                  );
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(role.displayName, style: const TextStyle(color: Colors.white, fontSize: 15)),
                if (user.role == role)
                  const Icon(Icons.check, color: AppTheme.brandPrimary, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Пользователи'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск по имени или никнейму',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _loadUsers();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (val) => _loadUsers(val.trim()),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
                : _users.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.person_search_outlined,
                        title: 'Пользователи не найдены',
                        subtitle: 'Попробуйте изменить поисковый запрос',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final user = _users[i];
                          return AppCard(
                            padding: const EdgeInsets.all(12),
                            onTap: () => _showChangeRoleDialog(user),
                            child: Row(
                              children: [
                                UserAvatar(user: user, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                      ),
                                      Text(
                                        '@${user.username}',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                      if (user.email != null)
                                        Text(
                                          user.email!,
                                          style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                                RoleBadge(role: user.role),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textTertiary),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
