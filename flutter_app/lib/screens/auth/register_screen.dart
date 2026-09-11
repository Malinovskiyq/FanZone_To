import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../user/user_nav_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _useEmail = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.error,
          content: Text('Пароли не совпадают'),
        ),
      );
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.register(
      email: _useEmail ? _contactController.text.trim() : null,
      phone: !_useEmail ? _contactController.text.trim() : null,
      username: _usernameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UserNavScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text(auth.errorMessage ?? 'Ошибка регистрации'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Регистрация'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        placeholder: 'Имя',
                        controller: _firstNameController,
                        validator: (v) => (v == null || v.isEmpty) ? 'Обязательно' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        placeholder: 'Фамилия',
                        controller: _lastNameController,
                        validator: (v) => (v == null || v.isEmpty) ? 'Обязательно' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  placeholder: 'Никнейм (@username)',
                  controller: _usernameController,
                  icon: Icons.alternate_email,
                  validator: (v) => (v == null || v.isEmpty) ? 'Введите никнейм' : null,
                ),
                const SizedBox(height: 14),

                // Toggle Email / Phone
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Email')),
                    ButtonSegment(value: false, label: Text('Телефон')),
                  ],
                  selected: {_useEmail},
                  onSelectionChanged: (set) {
                    setState(() {
                      _useEmail = set.first;
                    });
                  },
                ),
                const SizedBox(height: 14),

                AppTextField(
                  placeholder: _useEmail ? 'Email' : '+7 (999) 000-00-00',
                  controller: _contactController,
                  icon: _useEmail ? Icons.email_outlined : Icons.phone_outlined,
                  keyboardType: _useEmail ? TextInputType.emailAddress : TextInputType.phone,
                  validator: (v) => (v == null || v.isEmpty) ? 'Введите контакт' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  placeholder: 'Пароль',
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  isSecure: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  placeholder: 'Повторите пароль',
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  isSecure: true,
                  validator: (v) => (v == null || v.isEmpty) ? 'Повторите пароль' : null,
                ),
                const SizedBox(height: 28),

                AppPrimaryButton(
                  title: 'ЗАРЕГИСТРИРОВАТЬСЯ',
                  isLoading: auth.isLoading,
                  onPressed: _handleRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
