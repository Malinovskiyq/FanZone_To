import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/booking.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import 'booking_sheet.dart';
import 'ticket_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final Match match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late Match _match;
  Booking? _existingBooking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final updatedMatch = await ApiService().getMatch(_match.id);
      final myBookings = await ApiService().getMyBookings();
      Booking? found;
      for (final b in myBookings) {
        if (b.match.id == _match.id) {
          found = b;
          break;
        }
      }
      setState(() {
        _match = updatedMatch;
        _existingBooking = found;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _openBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingSheet(
        match: _match,
        onSuccess: _loadDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_match.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Match Banner
                  _buildHeroBanner(),
                  const SizedBox(height: 16),

                  // Arena & Time Card
                  AppCard(
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.calendar_today, 'Дата', _match.formattedDate),
                        const Divider(color: AppTheme.surfaceElevated),
                        _buildInfoRow(Icons.access_time, 'Время', _match.formattedTime),
                        const Divider(color: AppTheme.surfaceElevated),
                        _buildInfoRow(Icons.stadium, 'Арена', _match.arena.name),
                        const Divider(color: AppTheme.surfaceElevated),
                        _buildInfoRow(Icons.location_on, 'Город', _match.arena.city),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fan Sector Card
                  if (_match.fanSector != null) _buildSectorCard(),
                  const SizedBox(height: 16),

                  // Description
                  if (_match.description != null && _match.description!.isNotEmpty) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Информация о матче',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _match.description!,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Button or Existing Booking
                  _buildActionSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildLogo(_match.homeTeam),
                    const SizedBox(height: 8),
                    Text(
                      _match.homeTeam.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.brandSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  BookingWindowBadge(
                    isOpen: _match.isBookingOpen,
                    availableSeats: _match.availableSeats,
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildLogo(_match.awayTeam),
                    const SizedBox(height: 8),
                    Text(
                      _match.awayTeam.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Team team) {
    final logoUrl = team.logoFullUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        width: 58,
        height: 58,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackLogo(team.name),
      );
    }
    return _buildFallbackLogo(team.name);
  }

  Widget _buildFallbackLogo(String name) {
    final text = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.brandPrimary, fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectorCard() {
    final sector = _match.fanSector!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sector.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              Text(
                'Свободно: ${_match.availableSeats} из ${sector.capacity}',
                style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _match.occupancyPercent,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPrimary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (_existingBooking != null) {
      return AppCard(
        color: AppTheme.surfaceSecondary,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ваша заявка:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                BookingStatusBadge(status: _existingBooking!.status),
              ],
            ),
            if (_existingBooking!.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 12),
              AppPrimaryButton(
                title: 'ОТКРЫТЬ БИЛЕТ',
                icon: Icons.qr_code,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TicketScreen(booking: _existingBooking!)),
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

    return AppPrimaryButton(
      title: _match.isBookingOpen ? 'ЗАБРОНИРОВАТЬ МЕСТО' : 'БРОНИРОВАНИЕ ЗАКРЫТО',
      onPressed: _match.isBookingOpen ? _openBookingSheet : null,
    );
  }
}
