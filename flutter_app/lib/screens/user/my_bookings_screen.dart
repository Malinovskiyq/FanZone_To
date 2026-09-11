import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import 'ticket_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTab = 0; // 0 = upcoming, 1 = history
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getMyBookings();
      setState(() {
        _bookings = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Отменить бронь?'),
        content: Text('Вы уверены, что хотите отменить заявку на матч ${booking.match.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Назад')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отменить', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().cancelBooking(booking.id);
        _loadBookings();
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
    final upcomingList = _bookings.where((b) => b.isUpcoming).toList();
    final historyList = _bookings.where((b) => !b.isUpcoming).toList();
    final currentList = _selectedTab == 0 ? upcomingList : historyList;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Мои брони'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text('Предстоящие (${upcomingList.length})'),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('История (${historyList.length})'),
                ),
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
                          children: [
                            const SizedBox(height: 80),
                            EmptyStateView(
                              icon: _selectedTab == 0 ? Icons.confirmation_number_outlined : Icons.history,
                              title: _selectedTab == 0 ? 'Нет активных броней' : 'История пуста',
                              subtitle: _selectedTab == 0
                                  ? 'Забронируйте билет на ближайший матч прямо сейчас'
                                  : 'Здесь будут отображаться ваши прошедшие бронирования',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: currentList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (ctx, i) {
                            final booking = currentList[i];
                            return _buildBookingCard(booking);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.match.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              BookingStatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${booking.match.formattedDateTime} · ${booking.match.arena.name}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          if (booking.sectorName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Сектор: ${booking.sectorName}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppTheme.surfaceElevated, height: 1),
          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              Text(
                'Заявка #${booking.shortId}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textTertiary),
              ),
              const Spacer(),
              if (booking.status == BookingStatus.confirmed)
                TextButton.icon(
                  icon: const Icon(Icons.qr_code, size: 16, color: AppTheme.brandPrimary),
                  label: const Text('БИЛЕТ', style: TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TicketScreen(booking: booking)),
                    );
                  },
                ),
              if (booking.canCancel)
                TextButton(
                  onPressed: () => _cancelBooking(booking),
                  child: const Text('Отменить', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
