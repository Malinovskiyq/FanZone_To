import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/stats.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final s = await ApiService().getMyStats();
      setState(() {
        _stats = s;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    final fn = TextEditingController(text: user?.profile?.firstName ?? '');
    final ln = TextEditingController(text: user?.profile?.lastName ?? '');
    final city = TextEditingController(text: user?.profile?.city ?? '');
    final bio = TextEditingController(text: user?.profile?.bio ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Редактировать профиль'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(placeholder: 'Имя', controller: fn),
              const SizedBox(height: 10),
              AppTextField(placeholder: 'Фамилия', controller: ln),
              const SizedBox(height: 10),
              AppTextField(placeholder: 'Город', controller: city),
              const SizedBox(height: 10),
              AppTextField(placeholder: 'О себе', controller: bio),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService().updateProfile(
                  firstName: fn.text.trim(),
                  lastName: ln.text.trim(),
                  city: city.text.trim().isNotEmpty ? city.text.trim() : null,
                  bio: bio.text.trim().isNotEmpty ? bio.text.trim() : null,
                );
                await auth.refreshProfile();
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showAddSocialLinkDialog() {
    final auth = Provider.of<AuthService>(context, listen: false);
    String platform = 'TELEGRAM';
    final urlController = TextEditingController();
    final labelController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Добавить ссылку'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: platform,
                dropdownColor: AppTheme.surfaceElevated,
                items: const [
                  DropdownMenuItem(value: 'TELEGRAM', child: Text('Telegram')),
                  DropdownMenuItem(value: 'VK', child: Text('VKontakte')),
                  DropdownMenuItem(value: 'INSTAGRAM', child: Text('Instagram')),
                  DropdownMenuItem(value: 'YOUTUBE', child: Text('YouTube')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Другое')),
                ],
                onChanged: (val) => setDialogState(() => platform = val!),
                decoration: const InputDecoration(labelText: 'Платформа'),
              ),
              const SizedBox(height: 12),
              AppTextField(placeholder: 'Ссылка (URL)', controller: urlController),
              const SizedBox(height: 12),
              AppTextField(placeholder: 'Подпись (необязательно)', controller: labelController),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final url = urlController.text.trim();
                if (url.isEmpty) return;
                try {
                  await ApiService().addSocialLink(
                    platform,
                    url,
                    labelController.text.trim().isNotEmpty ? labelController.text.trim() : null,
                  );
                  await auth.refreshProfile();
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
                    );
                  }
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Выйти из аккаунта?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<AuthService>(context, listen: false).logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await auth.refreshProfile();
          await _loadProfileData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Card
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    UserAvatar(user: user, size: 70, showBorder: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Болельщик',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user?.username ?? ''}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          if (user?.profile?.city != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  user!.profile!.city!,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          RoleBadge(role: user?.role ?? UserRole.user),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Statistics Grid
              const Text(
                'Статистика посещений',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      emoji: '🏒',
                      value: '${_stats?.attendedMatches ?? 0}',
                      label: 'Посещено',
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      emoji: '🎟',
                      value: '${_stats?.confirmedBookings ?? 0}',
                      label: 'Подтверждено',
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      emoji: '📅',
                      value: '${_stats?.totalBookings ?? 0}',
                      label: 'Всего броней',
                      color: AppTheme.brandSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      emoji: '❌',
                      value: '${_stats?.cancelledBookings ?? 0}',
                      label: 'Отменено',
                      color: AppTheme.neutral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Social Links Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Социальные сети',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16, color: AppTheme.brandPrimary),
                    label: const Text('Добавить', style: TextStyle(color: AppTheme.brandPrimary)),
                    onPressed: _showAddSocialLinkDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (user?.socialLinks != null && user!.socialLinks!.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: user.socialLinks!.map((s) {
                    return ActionChip(
                      backgroundColor: AppTheme.surface,
                      avatar: const Icon(Icons.link, size: 16, color: AppTheme.brandPrimary),
                      label: Text(s.label ?? s.platform),
                      onPressed: () async {
                        final uri = Uri.tryParse(s.url);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    );
                  }).toList(),
                )
              else
                const Text(
                  'Ссылки не добавлены. Добавьте свои соцсети, чтобы ответственный за сектор мог с вами связаться.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),

              const SizedBox(height: 24),

              // Attendance History
              if (_stats != null && _stats!.recentAttendances.isNotEmpty) ...[
                const Text(
                  'История последних матчей',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _stats!.recentAttendances.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = _stats!.recentAttendances[i];
                    return AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            item.attendanceStatus == AttendanceStatus.attended
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 20,
                            color: item.attendanceStatus == AttendanceStatus.attended
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.matchTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                ),
                                Text(
                                  item.attendanceStatus.displayName,
                                  style: TextStyle(color: item.attendanceStatus.color, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Logout Button
              AppDestructiveButton(
                title: 'ВЫЙТИ ИЗ АККАУНТА',
                onPressed: _handleLogout,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
