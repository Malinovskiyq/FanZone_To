import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'user/user_nav_screen.dart';
import 'manager/manager_nav_screen.dart';
import 'admin/admin_nav_screen.dart';
import '../models/user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.init();

    if (!mounted) return;

    if (!auth.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      Widget nextScreen;
      switch (auth.role) {
        case UserRole.admin:
          nextScreen = const AdminNavScreen();
          break;
        case UserRole.bookingManager:
          nextScreen = const ManagerNavScreen();
          break;
        case UserRole.user:
          nextScreen = const UserNavScreen();
          break;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.heroGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandPrimary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_hockey,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ХК СИБИРЬ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'FanZone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: AppTheme.brandPrimary),
          ],
        ),
      ),
    );
  }
}
