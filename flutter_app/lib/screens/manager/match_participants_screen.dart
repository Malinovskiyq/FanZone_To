import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/user_avatar.dart';

class MatchParticipantsScreen extends StatefulWidget {
  const MatchParticipantsScreen({super.key});

  @override
  State<MatchParticipantsScreen> createState() => _MatchParticipantsScreenState();
}

class _MatchParticipantsScreenState extends State<MatchParticipantsScreen> {
  List<Match> _matches = [];
  Match? _selectedMatch;
  List<MatchParticipant> _participants = [];
  bool _isLoadingMatches = true;
  bool _isLoadingParticipants = false;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await ApiService().getMatches();
      setState(() {
        _matches = matches;
        _selectedMatch = matches.isNotEmpty ? matches.first : null;
        _isLoadingMatches = false;
      });
      if (_selectedMatch != null) {
        _loadParticipants(_selectedMatch!.id);
      }
    } catch (_) {
      setState(() => _isLoadingMatches = false);
    }
  }

  Future<void> _loadParticipants(String matchId) async {
    setState(() => _isLoadingParticipants = true);
    try {
      final p = await ApiService().getMatchParticipants(matchId);
      setState(() {
        _participants = p;
        _isLoadingParticipants = false;
      });
    } catch (_) {
      setState(() => _isLoadingParticipants = false);
    }
  }

  Future<void> _markAttendance(String bookingId, String status) async {
    try {
      await ApiService().markAttendance(bookingId, status);
      if (_selectedMatch != null) {
        _loadParticipants(_selectedMatch!.id);
      }
    } catch (e) {
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
      appBar: AppBar(title: const Text('Участники матча')),
      body: _isLoadingMatches
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : Column(
              children: [
                // Match Dropdown
                if (_matches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.surfaceElevated),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Match>(
                          value: _selectedMatch,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceElevated,
                          items: _matches.map((m) {
                            return DropdownMenuItem<Match>(
                              value: m,
                              child: Text(
                                '${m.title} (${m.formattedDate})',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMatch = val);
                              _loadParticipants(val.id);
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                // Participants List
                Expanded(
                  child: _isLoadingParticipants
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
                      : _participants.isEmpty
                          ? const EmptyStateView(
                              icon: Icons.people_outline,
                              title: 'Нет участников',
                              subtitle: 'На этот матч пока нет подтверждённых бронирований',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _participants.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final p = _participants[i];
                                final isAttended = p.attendanceStatus == 'ATTENDED';
                                final isAbsent = p.attendanceStatus == 'ABSENT';

                                return AppCard(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      UserAvatar(user: p.user, size: 40),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.user.displayName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              '@${p.user.username}',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Attendance buttons
                                      IconButton(
                                        icon: Icon(
                                          Icons.check_circle,
                                          color: isAttended ? AppTheme.success : AppTheme.textTertiary,
                                        ),
                                        tooltip: 'Отметить: Посетил',
                                        onPressed: () => _markAttendance(p.id, 'ATTENDED'),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.cancel,
                                          color: isAbsent ? AppTheme.error : AppTheme.textTertiary,
                                        ),
                                        tooltip: 'Отметить: Не явился',
                                        onPressed: () => _markAttendance(p.id, 'ABSENT'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
