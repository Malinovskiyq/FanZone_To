import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/match.dart';
import 'status_badge.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;

  const MatchCard({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teams header
                Row(
                  children: [
                    Expanded(child: _buildTeam(match.homeTeam, CrossAxisAlignment.start)),
                    _buildVsSection(),
                    Expanded(child: _buildTeam(match.awayTeam, CrossAxisAlignment.end)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.surfaceElevated, height: 1),
                const SizedBox(height: 10),

                // Info row
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      match.formattedDate,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time, size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      match.formattedTime,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    if (!match.isHome)
                      Row(
                        children: const [
                          Icon(Icons.flight_takeoff, size: 13, color: AppTheme.brandSecondary),
                          SizedBox(width: 4),
                          Text(
                            'Выездной',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Sector & Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          match.fanSector != null
                              ? '${match.fanSector!.name} · ${match.availableSeats} мест'
                              : match.arena.name,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    BookingWindowBadge(
                      isOpen: match.isBookingOpen,
                      availableSeats: match.availableSeats,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeam(Team team, CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        _buildLogo(team),
        const SizedBox(height: 6),
        Text(
          team.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildLogo(Team team) {
    final logoUrl = team.logoFullUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildLogoFallback(team.name),
      );
    }
    return _buildLogoFallback(team.name);
  }

  Widget _buildLogoFallback(String name) {
    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppTheme.brandPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildVsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: const Text(
        'VS',
        style: TextStyle(
          color: AppTheme.brandSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
