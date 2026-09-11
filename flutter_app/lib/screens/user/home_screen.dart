import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/match_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';
import 'booking_sheet.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Match> _upcomingMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await ApiService().getMatches(filter: 'upcoming');
      setState(() {
        _upcomingMatches = matches;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Match? get _nextMatch => _upcomingMatches.isNotEmpty ? _upcomingMatches.first : null;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.brandPrimary,
          onRefresh: _loadMatches,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Greeting & Avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ХК СИБИРЬ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppTheme.brandSecondary,
                          ),
                        ),
                        Text(
                          'Привет, ${auth.currentUser?.profile?.firstName ?? auth.currentUser?.username ?? 'Болельщик'}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    UserAvatar(user: auth.currentUser, size: 44, showBorder: true),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero Card: Next Match
                if (_isLoading)
                  const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary)),
                  )
                else if (_nextMatch != null)
                  _buildNextMatchHero(_nextMatch!)
                else
                  const AppCard(
                    child: EmptyStateView(
                      icon: Icons.sports_hockey,
                      title: 'Нет предстоящих матчей',
                      subtitle: 'Следите за расписанием новых игр',
                    ),
                  ),

                const SizedBox(height: 26),

                // Other upcoming matches
                if (_upcomingMatches.length > 1) ...[
                  const Text(
                    'Ближайшие матчи',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _upcomingMatches.length - 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final match = _upcomingMatches[i + 1];
                      return MatchCard(
                        match: match,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextMatchHero(Match match) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPrimary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top gradient hero
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'СЛЕДУЮЩИЙ МАТЧ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppTheme.brandSecondary,
                      ),
                    ),
                    BookingWindowBadge(
                      isOpen: match.isBookingOpen,
                      availableSeats: match.availableSeats,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Teams Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildLogo(match.homeTeam),
                          const SizedBox(height: 8),
                          Text(
                            match.homeTeam.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.brandSecondary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLogo(match.awayTeam),
                          const SizedBox(height: 8),
                          Text(
                            match.awayTeam.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Match details chip row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPill(Icons.calendar_today, match.formattedDate),
                    const SizedBox(width: 8),
                    _buildPill(Icons.access_time, match.formattedTime),
                    const SizedBox(width: 8),
                    _buildPill(Icons.stadium, match.arena.name),
                  ],
                ),
              ],
            ),
          ),

          // Bottom booking bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (match.fanSector != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          match.fanSector!.name,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        Text(
                          'Свободно: ${match.availableSeats} мест',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: match.availableSeats > 10 ? AppTheme.success : AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                AppPrimaryButton(
                  title: match.isBookingOpen ? 'ЗАБРОНИРОВАТЬ БИЛЕТ' : 'БРОНИРОВАНИЕ ЗАКРЫТО',
                  onPressed: match.isBookingOpen
                      ? () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => BookingSheet(match: match, onSuccess: _loadMatches),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Team team) {
    final url = team.logoFullUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: 52,
        height: 52,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackLogo(team.name),
      );
    }
    return _buildFallbackLogo(team.name);
  }

  Widget _buildFallbackLogo(String name) {
    final text = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.brandPrimary, fontSize: 16, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}
