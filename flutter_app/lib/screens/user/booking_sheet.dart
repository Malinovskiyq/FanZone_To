import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/user_avatar.dart';

class BookingSheet extends StatefulWidget {
  final Match match;
  final VoidCallback? onSuccess;

  const BookingSheet({super.key, required this.match, this.onSuccess});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);
    try {
      await ApiService().createBooking(
        widget.match.id,
        _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });
      widget.onSuccess?.call();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: _isSuccess ? _buildSuccessView() : _buildFormView(auth),
      ),
    );
  }

  Widget _buildFormView(AuthService auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Заявка в фан-сектор',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),

        // Match Info Card
        AppCard(
          padding: const EdgeInsets.all(14),
          color: AppTheme.surfaceSecondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.match.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.match.formattedDateTime} · ${widget.match.arena.name}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              if (widget.match.fanSector != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 14, color: AppTheme.brandPrimary),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.match.fanSector!.name} (Осталось мест: ${widget.match.availableSeats})',
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // User info confirmation
        AppCard(
          padding: const EdgeInsets.all(14),
          color: AppTheme.surfaceSecondary,
          child: Row(
            children: [
              UserAvatar(user: auth.currentUser, size: 44),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Бронирование для:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  Text(
                    auth.currentUser?.displayName ?? 'Болельщик',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Notes
        TextField(
          controller: _notesController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Комментарий к заявке (необязательно)',
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            filled: true,
            fillColor: AppTheme.surfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Заявка поступает на рассмотрение ответственному за сектор. После подтверждения билет появится в разделе "Мои брони".',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        AppPrimaryButton(
          title: 'ОТПРАВИТЬ ЗАЯВКУ',
          isLoading: _isLoading,
          onPressed: _submitBooking,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.check_circle, size: 68, color: AppTheme.success),
        const SizedBox(height: 16),
        const Text(
          'Заявка отправлена!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Заявка на матч ${widget.match.title} успешно зарегистрирована. Ожидайте подтверждения от ответственного.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        AppPrimaryButton(
          title: 'ПОНЯТНО',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
