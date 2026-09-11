import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';

class TicketScreen extends StatefulWidget {
  final Booking booking;

  const TicketScreen({super.key, required this.booking});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  Ticket? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    try {
      final t = await ApiService().getTicket(widget.booking.id);
      setState(() {
        _ticket = t;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _ticket = widget.booking.ticket;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Электронный билет'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildTicketCard(),
            ),
    );
  }

  Widget _buildTicketCard() {
    final ticket = _ticket ?? widget.booking.ticket;
    final isUsed = ticket?.isUsed ?? false;
    final qrToken = ticket?.qrToken ?? widget.booking.id;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Brand Stripe
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.sports_hockey, size: 20, color: AppTheme.brandPrimary),
                        SizedBox(width: 8),
                        Text(
                          'ХК СИБИРЬ · FANZONE',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isUsed ? AppTheme.error : AppTheme.success).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isUsed ? 'ИСПОЛЬЗОВАН' : 'ДЕЙСТВИТЕЛЕН',
                        style: TextStyle(
                          color: isUsed ? AppTheme.error : AppTheme.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Match details
                Text(
                  widget.booking.match.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.booking.match.formattedDateTime,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.booking.match.arena.name,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),

                // Sector badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stadium, size: 18, color: AppTheme.brandSecondary),
                      const SizedBox(width: 8),
                      Text(
                        widget.booking.sectorName ?? 'Фан-сектор',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: qrToken,
                    version: QrVersions.auto,
                    size: 190.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Ticket ID & Disclaimer
                Text(
                  'ID: ${widget.booking.shortId}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Покажите этот QR-код ответственному при входе в сектор',
                  style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Bottom accent line
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.brandSecondary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
          ),
        ],
      ),
    );
  }
}
