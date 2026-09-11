import 'package:flutter/material.dart';
import '../manager/booking_requests_screen.dart';
import '../user/home_screen.dart';
import 'admin_matches_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_users_screen.dart';

class AdminNavScreen extends StatefulWidget {
  const AdminNavScreen({super.key});

  @override
  State<AdminNavScreen> createState() => _AdminNavScreenState();
}

class _AdminNavScreenState extends State<AdminNavScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    AdminMatchesScreen(),
    BookingRequestsScreen(),
    AdminUsersScreen(),
    AdminStatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_hockey_outlined),
            activeIcon: Icon(Icons.sports_hockey),
            label: 'Матчи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Заявки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Люди',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Статистика',
          ),
        ],
      ),
    );
  }
}
