import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';
import 'user_detail_screen.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  int _selectedTab = 0; // 0: PENDING, 1: CONFIRMED, 2: REJECTED
  List<Booking> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getAllBookings();
      setState(() {
        _allBookings = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirm(Booking booking) async {
    try {
      await ApiService().confirmBooking(booking.id);
      _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.success, content: Text('Заявка #${booking.shortId} подтверждена')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
      );
    }
  }

  Future<void> _reject(Booking booking) async {
    try {
      await ApiService().rejectBooking(booking.id);
      _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.neutral, content: Text('Заявка #${booking.shortId} отклонена')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _allBookings.where((b) => b.status == BookingStatus.pending).toList();
    final confirmed = _allBookings.where((b) => b.status == BookingStatus.confirmed).toList();
    final rejected = _allBookings.where((b) => b.status == BookingStatus.rejected).toList();

    final currentList = _selectedTab == 0
        ? pending
        : (_selectedTab == 1 ? confirmed : rejected);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Заявки в фан-сектор'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text('Новые (${pending.length})')),
                ButtonSegment(value: 1, label: Text('Подтвержд. (${confirmed.length})')),
                ButtonSegment(value: 2, label: Text('Отклон. (${rejected.length})')),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (set) => setState(() => _selectedTab = set.first),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
                : currentList.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyStateView(
                              icon: Icons.inbox_outlined,
                              title: 'Заявок нет',
                              subtitle: 'В этой вкладке пока нет заявок на бронирование',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: currentList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final booking = currentList[i];
                            return _buildRequestCard(booking);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Booking booking) {
    final isPending = booking.status == BookingStatus.pending;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User row
          InkWell(
            onTap: booking.user != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => UserDetailScreen(user: booking.user!)),
                    );
                  }
                : null,
            child: Row(
              children: [
                UserAvatar(user: booking.user, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.user?.displayName ?? 'Болельщик',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      Text(
                        '@${booking.user?.username ?? ''}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                BookingStatusBadge(status: booking.status),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.surfaceElevated, height: 1),
          const SizedBox(height: 10),

          // Match info
          Text(
            booking.match.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${booking.match.formattedDateTime} · ${booking.match.arena.name}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Комментарий: ${booking.notes}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          // Buttons for pending
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangle.circular(10),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('ОТКЛОНИТЬ'),
                    onPressed: () => _reject(booking),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangle.circular(10),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('ПОДТВЕРДИТЬ'),
                    onPressed: () => _confirm(booking),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
