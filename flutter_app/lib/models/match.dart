import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import 'user.dart';

enum MatchStatus {
  scheduled,
  ongoing,
  completed,
  cancelled;

  static MatchStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'ONGOING':
        return MatchStatus.ongoing;
      case 'COMPLETED':
        return MatchStatus.completed;
      case 'CANCELLED':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.scheduled;
    }
  }

  String get displayName {
    switch (this) {
      case MatchStatus.scheduled:
        return 'Запланирован';
      case MatchStatus.ongoing:
        return 'Идёт';
      case MatchStatus.completed:
        return 'Завершён';
      case MatchStatus.cancelled:
        return 'Отменён';
    }
  }
}

class Team {
  final String id;
  final String name;
  final String? city;
  final String? logoUrl;
  final bool isHome;

  Team({
    required this.id,
    required this.name,
    this.city,
    this.logoUrl,
    this.isHome = false,
  });

  String? get logoFullUrl {
    if (logoUrl == null || logoUrl!.isEmpty) return null;
    if (logoUrl!.startsWith('http')) return logoUrl;
    return '${AppConfig.uploadsBaseUrl}/$logoUrl';
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'],
      logoUrl: json['logoUrl'] ?? json['logo_url'],
      isHome: json['isHome'] ?? json['is_home'] ?? false,
    );
  }
}

class Arena {
  final String id;
  final String name;
  final String city;
  final String? address;

  Arena({
    required this.id,
    required this.name,
    required this.city,
    this.address,
  });

  factory Arena.fromJson(Map<String, dynamic> json) {
    return Arena(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'],
    );
  }
}

class FanSector {
  final String id;
  final String name;
  final int capacity;

  FanSector({
    required this.id,
    required this.name,
    required this.capacity,
  });

  factory FanSector.fromJson(Map<String, dynamic> json) {
    return FanSector(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 0,
    );
  }
}

class Match {
  final String id;
  final Team homeTeam;
  final Team awayTeam;
  final Arena arena;
  final DateTime scheduledAt;
  final DateTime bookingOpenAt;
  final DateTime bookingCloseAt;
  final String? description;
  final bool isHome;
  final MatchStatus status;
  final int cancelDeadlineHours;
  final FanSector? fanSector;
  final int confirmedBookingsCount;
  final int pendingBookingsCount;

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.arena,
    required this.scheduledAt,
    required this.bookingOpenAt,
    required this.bookingCloseAt,
    this.description,
    this.isHome = true,
    required this.status,
    this.cancelDeadlineHours = 24,
    this.fanSector,
    this.confirmedBookingsCount = 0,
    this.pendingBookingsCount = 0,
  });

  String get title => '${homeTeam.name} — ${awayTeam.name}';

  int get availableSeats {
    if (fanSector == null) return 0;
    final left = fanSector!.capacity - confirmedBookingsCount;
    return left > 0 ? left : 0;
  }

  bool get isBookingOpen {
    final now = DateTime.now();
    if (status == MatchStatus.completed || status == MatchStatus.cancelled) {
      return false;
    }
    if (now.isBefore(bookingOpenAt) || now.isAfter(bookingCloseAt)) {
      return false;
    }
    return availableSeats > 0;
  }

  String get formattedDateTime {
    return DateFormat("d MMMM 'в' HH:mm", 'ru').format(scheduledAt);
  }

  String get formattedDate {
    return DateFormat("d MMMM", 'ru').format(scheduledAt);
  }

  String get formattedTime {
    return DateFormat("HH:mm").format(scheduledAt);
  }

  double get occupancyPercent {
    if (fanSector == null || fanSector!.capacity == 0) return 0.0;
    return (confirmedBookingsCount / fanSector!.capacity).clamp(0.0, 1.0);
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? '',
      homeTeam: Team.fromJson(json['homeTeam'] ?? json['home_team'] ?? {'name': 'Хозяева'}),
      awayTeam: Team.fromJson(json['awayTeam'] ?? json['away_team'] ?? {'name': 'Гости'}),
      arena: Arena.fromJson(json['arena'] ?? {'name': 'Арена', 'city': 'Город'}),
      scheduledAt: DateTime.tryParse(json['scheduledAt'] ?? '') ?? DateTime.now(),
      bookingOpenAt: DateTime.tryParse(json['bookingOpenAt'] ?? '') ?? DateTime.now(),
      bookingCloseAt: DateTime.tryParse(json['bookingCloseAt'] ?? '') ?? DateTime.now(),
      description: json['description'],
      isHome: json['isHome'] ?? json['is_home'] ?? true,
      status: MatchStatus.fromString(json['status']),
      cancelDeadlineHours: json['cancelDeadlineHours'] ?? 24,
      fanSector: json['fanSector'] != null ? FanSector.fromJson(json['fanSector']) : null,
      confirmedBookingsCount: json['confirmedBookingsCount'] ?? json['confirmed_bookings_count'] ?? 0,
      pendingBookingsCount: json['pendingBookingsCount'] ?? json['pending_bookings_count'] ?? 0,
    );
  }
}

class MatchParticipant {
  final String id;
  final User user;
  final String status;
  final String attendanceStatus;

  MatchParticipant({
    required this.id,
    required this.user,
    required this.status,
    required this.attendanceStatus,
  });

  factory MatchParticipant.fromJson(Map<String, dynamic> json) {
    return MatchParticipant(
      id: json['id'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      status: json['status'] ?? 'PENDING',
      attendanceStatus: json['attendance']?['status'] ?? 'UNKNOWN',
    );
  }
}
