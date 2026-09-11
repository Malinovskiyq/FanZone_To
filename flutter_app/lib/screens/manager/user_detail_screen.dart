import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/stats.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  UserStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final s = await ApiService().getUserStats(widget.user.id);
      setState(() {
        _stats = s;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(widget.user.displayName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        UserAvatar(user: widget.user, size: 64, showBorder: true),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.displayName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text('@${widget.user.username}', style: const TextStyle(color: AppTheme.textSecondary)),
                              if (widget.user.phone != null) ...[
                                const SizedBox(height: 2),
                                Text(widget.user.phone!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                              const SizedBox(height: 6),
                              RoleBadge(role: widget.user.role),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_stats != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            emoji: '🏒',
                            value: '${_stats!.attendedMatches}',
                            label: 'Посещено',
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            emoji: '🎟',
                            value: '${_stats!.confirmedBookings}',
                            label: 'Подтверждено',
                            color: AppTheme.brandPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            emoji: '❌',
                            value: '${_stats!.absentMatches}',
                            label: 'Не явился',
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
    );
  }
}
