import 'package:flutter/material.dart';
import '../user/matches_screen.dart';
import '../user/profile_screen.dart';
import 'booking_requests_screen.dart';
import 'match_participants_screen.dart';
import 'qr_scanner_screen.dart';

class ManagerNavScreen extends StatefulWidget {
  const ManagerNavScreen({super.key});

  @override
  State<ManagerNavScreen> createState() => _ManagerNavScreenState();
}

class _ManagerNavScreenState extends State<ManagerNavScreen> {
  int _currentIndex = 0;

  final _screens = const [
    BookingRequestsScreen(),
    MatchesScreen(),
    MatchParticipantsScreen(),
    QrScannerScreen(),
    ProfileScreen(),
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
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Заявки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_hockey_outlined),
            activeIcon: Icon(Icons.sports_hockey),
            label: 'Матчи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Участники',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Сканер',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
