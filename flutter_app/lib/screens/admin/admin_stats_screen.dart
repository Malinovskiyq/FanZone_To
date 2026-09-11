import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/stats.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  AdminOverviewStats? _overview;
  List<AdminMatchStats> _matchStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final o = await ApiService().getAdminOverviewStats();
      final m = await ApiService().getAdminMatchStats();
      setState(() {
        _overview = o;
        _matchStats = m;
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
      appBar: AppBar(title: const Text('Статистика клуба')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Overview Grid
                    const Text(
                      'Общие показатели',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    if (_overview != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              emoji: '👥',
                              value: '${_overview!.totalUsers}',
                              label: 'Болельщиков',
                              color: AppTheme.info,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              emoji: '📋',
                              value: '${_overview!.totalBookings}',
                              label: 'Всего заявок',
                              color: AppTheme.brandSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              emoji: '✅',
                              value: '${_overview!.confirmedBookings}',
                              label: 'Подтверждено',
                              color: AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              emoji: '🏒',
                              value: '${_overview!.totalAttended}',
                              label: 'Посетило',
                              color: AppTheme.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                    // Per-Match Statistics
                    const Text(
                      'Статистика по матчам',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    if (_matchStats.isEmpty)
                      const AppCard(
                        child: Text(
                          'Нет данных по матчам',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _matchStats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final stat = _matchStats[i];
                          return AppCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stat.matchTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMetric('Вместимость', '${stat.totalCapacity}'),
                                    _buildMetric('Бронь', '${stat.confirmedBookings}'),
                                    _buildMetric('Посетили', '${stat.attended}', AppTheme.success),
                                    _buildMetric('Не явились', '${stat.absent}', AppTheme.error),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: stat.occupancyPercent,
                                    backgroundColor: AppTheme.surfaceElevated,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPrimary),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetric(String label, String value, [Color color = Colors.white]) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}
