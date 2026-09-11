import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import 'create_match_screen.dart';

class AdminMatchesScreen extends StatefulWidget {
  const AdminMatchesScreen({super.key});

  @override
  State<AdminMatchesScreen> createState() => _AdminMatchesScreenState();
}

class _AdminMatchesScreenState extends State<AdminMatchesScreen> {
  List<Match> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final m = await ApiService().getMatches();
      setState(() {
        _matches = m;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMatch(Match match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Удалить матч?'),
        content: Text('Вы уверены, что хотите удалить матч ${match.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().deleteMatch(match.id);
        _loadMatches();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Управление матчами'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brandPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('СОЗДАТЬ МАТЧ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateMatchScreen()),
          );
          if (created == true) _loadMatches();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : _matches.isEmpty
              ? const EmptyStateView(
                  icon: Icons.sports_hockey,
                  title: 'Нет матчей',
                  subtitle: 'Нажмите кнопку ниже, чтобы создать матч',
                )
              : RefreshIndicator(
                  onRefresh: _loadMatches,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final m = _matches[i];
                      return AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    m.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                BookingWindowBadge(isOpen: m.isBookingOpen, availableSeats: m.availableSeats),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${m.formattedDateTime} · ${m.arena.name}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            if (m.fanSector != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Сектор: ${m.fanSector!.name} (Вместимость: ${m.fanSector!.capacity}, Занято: ${m.confirmedBookingsCount})',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 10),
                            const Divider(color: AppTheme.surfaceElevated, height: 1),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Удалить', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _deleteMatch(m),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
