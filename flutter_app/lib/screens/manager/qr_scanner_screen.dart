import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/user_avatar.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _tokenController = TextEditingController();
  QrVerificationResult? _result;
  bool _isLoading = false;
  bool _isMarking = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken(String token) async {
    if (token.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final res = await ApiService().verifyQR(token.trim());
      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
      );
    }
  }

  Future<void> _markAttended() async {
    final qrToken = _tokenController.text.trim();
    if (qrToken.isEmpty) return;

    setState(() => _isMarking = true);
    try {
      await ApiService().markAttendedByQR(qrToken);
      setState(() {
        _isMarking = false;
        // Refresh result to marked
        _result = QrVerificationResult(
          isValid: true,
          isUsed: true,
          booking: _result?.booking,
          message: 'Посещение успешно отмечено!',
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.success, content: Text('Билет отмечен как использованный')),
      );
    } catch (e) {
      setState(() => _isMarking = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
      );
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _tokenController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Сканер билетов'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Scanner view card / token input
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.brandPrimary, width: 2),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      size: 70,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Проверка QR-кода билета',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Вставьте токен билета или используйте сканер камеры',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    placeholder: 'QR Токен билета',
                    controller: _tokenController,
                    icon: Icons.qr_code,
                  ),
                  const SizedBox(height: 14),
                  AppPrimaryButton(
                    title: 'ПРОВЕРИТЬ БИЛЕТ',
                    isLoading: _isLoading,
                    onPressed: () => _verifyToken(_tokenController.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Verification Result Card
            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final res = _result!;
    final booking = res.booking;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;

    if (!res.isValid) {
      statusColor = AppTheme.error;
      statusIcon = Icons.cancel;
      statusTitle = 'Билет не найден или недействителен';
    } else if (res.isUsed) {
      statusColor = AppTheme.warning;
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'Билет уже использован!';
    } else {
      statusColor = AppTheme.success;
      statusIcon = Icons.check_circle;
      statusTitle = 'Билет действителен!';
    }

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (booking != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppTheme.surfaceElevated),
            const SizedBox(height: 12),
            Row(
              children: [
                UserAvatar(user: booking.user, size: 48),
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
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              color: AppTheme.surfaceSecondary,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.match.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.match.formattedDateTime} · ${booking.sectorName ?? 'Фан-сектор'}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (res.isValid && !res.isUsed)
            AppPrimaryButton(
              title: 'ОТМЕТИТЬ ПОСЕЩЕНИЕ',
              icon: Icons.check,
              isLoading: _isMarking,
              onPressed: _markAttended,
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _reset,
            child: const Text('Сбросить / Новый билет', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}
