import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/match_card.dart';
import 'match_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String _selectedFilter = 'upcoming';
  List<Match> _matches = [];
  bool _isLoading = true;

  final _filters = [
    {'id': 'upcoming', 'label': 'Ближайшие'},
    {'id': 'past', 'label': 'Прошедшие'},
    {'id': 'home', 'label': 'Домашние'},
    {'id': 'away', 'label': 'Выездные'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getMatches(filter: _selectedFilter);
      setState(() {
        _matches = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Матчи'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f['label']!),
                    selected: isSelected,
                    selectedColor: AppTheme.brandPrimary,
                    backgroundColor: AppTheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedFilter = f['id']!);
                        _loadMatches();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Matches List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
                : _matches.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadMatches,
                        child: ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyStateView(
                              icon: Icons.sports_hockey,
                              title: 'Нет матчей',
                              subtitle: 'В этой категории пока нет запланированных игр',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMatches,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _matches.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (ctx, i) {
                            final match = _matches[i];
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
                      ),
          ),
        ],
      ),
    );
  }
}
