import 'booking.dart';

class AttendanceHistoryItem {
  final String id;
  final String matchTitle;
  final DateTime scheduledAt;
  final bool isHome;
  final AttendanceStatus attendanceStatus;
  final BookingStatus bookingStatus;

  AttendanceHistoryItem({
    required this.id,
    required this.matchTitle,
    required this.scheduledAt,
    this.isHome = true,
    required this.attendanceStatus,
    required this.bookingStatus,
  });

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryItem(
      id: json['id'] ?? '',
      matchTitle: json['matchTitle'] ?? 'Матч',
      scheduledAt: DateTime.tryParse(json['scheduledAt'] ?? '') ?? DateTime.now(),
      isHome: json['isHome'] ?? true,
      attendanceStatus: AttendanceStatus.fromString(json['attendanceStatus']),
      bookingStatus: BookingStatus.fromString(json['bookingStatus']),
    );
  }
}

class UserStats {
  final int totalBookings;
  final int confirmedBookings;
  final int rejectedBookings;
  final int cancelledBookings;
  final int attendedMatches;
  final int absentMatches;
  final int homeMatchesAttended;
  final int awayMatchesAttended;
  final List<AttendanceHistoryItem> recentAttendances;

  UserStats({
    this.totalBookings = 0,
    this.confirmedBookings = 0,
    this.rejectedBookings = 0,
    this.cancelledBookings = 0,
    this.attendedMatches = 0,
    this.absentMatches = 0,
    this.homeMatchesAttended = 0,
    this.awayMatchesAttended = 0,
    this.recentAttendances = const [],
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalBookings: json['totalBookings'] ?? 0,
      confirmedBookings: json['confirmedBookings'] ?? 0,
      rejectedBookings: json['rejectedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      attendedMatches: json['attendedMatches'] ?? 0,
      absentMatches: json['absentMatches'] ?? 0,
      homeMatchesAttended: json['homeMatchesAttended'] ?? 0,
      awayMatchesAttended: json['awayMatchesAttended'] ?? 0,
      recentAttendances: (json['recentAttendances'] as List?)
              ?.map((e) => AttendanceHistoryItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AdminOverviewStats {
  final int totalUsers;
  final int activeUsers;
  final int totalBookings;
  final int confirmedBookings;
  final int rejectedBookings;
  final int cancelledBookings;
  final int totalAttended;
  final int totalAbsent;
  final int upcomingMatches;
  final int completedMatches;

  AdminOverviewStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.totalBookings = 0,
    this.confirmedBookings = 0,
    this.rejectedBookings = 0,
    this.cancelledBookings = 0,
    this.totalAttended = 0,
    this.totalAbsent = 0,
    this.upcomingMatches = 0,
    this.completedMatches = 0,
  });

  factory AdminOverviewStats.fromJson(Map<String, dynamic> json) {
    return AdminOverviewStats(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      confirmedBookings: json['confirmedBookings'] ?? 0,
      rejectedBookings: json['rejectedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      totalAttended: json['totalAttended'] ?? 0,
      totalAbsent: json['totalAbsent'] ?? 0,
      upcomingMatches: json['upcomingMatches'] ?? 0,
      completedMatches: json['completedMatches'] ?? 0,
    );
  }
}

class AdminMatchStats {
  final String id;
  final String matchTitle;
  final DateTime scheduledAt;
  final int totalCapacity;
  final int totalBookings;
  final int confirmedBookings;
  final int pendingBookings;
  final int attended;
  final int absent;

  AdminMatchStats({
    required this.id,
    required this.matchTitle,
    required this.scheduledAt,
    this.totalCapacity = 0,
    this.totalBookings = 0,
    this.confirmedBookings = 0,
    this.pendingBookings = 0,
    this.attended = 0,
    this.absent = 0,
  });

  double get occupancyPercent {
    if (totalCapacity == 0) return 0.0;
    return (confirmedBookings / totalCapacity).clamp(0.0, 1.0);
  }

  factory AdminMatchStats.fromJson(Map<String, dynamic> json) {
    return AdminMatchStats(
      id: json['id'] ?? '',
      matchTitle: json['matchTitle'] ?? 'Матч',
      scheduledAt: DateTime.tryParse(json['scheduledAt'] ?? '') ?? DateTime.now(),
      totalCapacity: json['totalCapacity'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      confirmedBookings: json['confirmedBookings'] ?? 0,
      pendingBookings: json['pendingBookings'] ?? 0,
      attended: json['attended'] ?? 0,
      absent: json['absent'] ?? 0,
    );
  }
}
