import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _contactController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ApiService().forgotPassword(contact);
      setState(() {
        _isSuccess = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Сброс пароля')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _isSuccess ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        const Icon(Icons.lock_reset, size: 64, color: AppTheme.brandPrimary),
        const SizedBox(height: 16),
        const Text(
          'Восстановление доступа',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Введите email или телефон, указанный при регистрации. Мы отправим код для восстановления.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppTextField(
          placeholder: 'Email или телефон',
          controller: _contactController,
          icon: Icons.contact_mail_outlined,
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(
          title: 'ОТПРАВИТЬ',
          isLoading: _isLoading,
          onPressed: _handleSubmit,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 72, color: AppTheme.success),
          const SizedBox(height: 16),
          const Text(
            'Инструкции отправлены!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Проверьте вашу почту или SMS с кодом восстановления пароля.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          AppPrimaryButton(
            title: 'ВЕРНУТЬСЯ КО ВХОДУ',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
