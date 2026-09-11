import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'match.dart';
import 'user.dart';

enum BookingStatus {
  pending,
  confirmed,
  rejected,
  cancelled;

  static BookingStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'CONFIRMED':
        return BookingStatus.confirmed;
      case 'REJECTED':
        return BookingStatus.rejected;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'На рассмотрении';
      case BookingStatus.confirmed:
        return 'Подтверждено';
      case BookingStatus.rejected:
        return 'Отклонено';
      case BookingStatus.cancelled:
        return 'Отменено';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return AppTheme.warning;
      case BookingStatus.confirmed:
        return AppTheme.success;
      case BookingStatus.rejected:
        return AppTheme.error;
      case BookingStatus.cancelled:
        return AppTheme.neutral;
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.access_time_filled;
      case BookingStatus.confirmed:
        return Icons.verified;
      case BookingStatus.rejected:
        return Icons.cancel;
      case BookingStatus.cancelled:
        return Icons.block;
    }
  }
}

enum AttendanceStatus {
  unknown,
  attended,
  absent;

  static AttendanceStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'ATTENDED':
        return AttendanceStatus.attended;
      case 'ABSENT':
        return AttendanceStatus.absent;
      default:
        return AttendanceStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.unknown:
        return 'Не отмечен';
      case AttendanceStatus.attended:
        return 'Посетил';
      case AttendanceStatus.absent:
        return 'Не пришёл';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.unknown:
        return AppTheme.textSecondary;
      case AttendanceStatus.attended:
        return AppTheme.success;
      case AttendanceStatus.absent:
        return AppTheme.error;
    }
  }
}

class Ticket {
  final String id;
  final String bookingId;
  final String qrToken;
  final bool isUsed;
  final DateTime issuedAt;
  final DateTime? usedAt;
  final String? matchTitle;
  final String? sectorName;
  final String? userFullName;
  final String? avatarUrl;
  final DateTime? scheduledAt;
  final String? arenaName;
  final String? arenaCity;

  Ticket({
    required this.id,
    required this.bookingId,
    required this.qrToken,
    this.isUsed = false,
    required this.issuedAt,
    this.usedAt,
    this.matchTitle,
    this.sectorName,
    this.userFullName,
    this.avatarUrl,
    this.scheduledAt,
    this.arenaName,
    this.arenaCity,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? json['booking_id'] ?? '',
      qrToken: json['qrToken'] ?? json['qr_token'] ?? '',
      isUsed: json['isUsed'] ?? json['is_used'] ?? false,
      issuedAt: DateTime.tryParse(json['issuedAt'] ?? '') ?? DateTime.now(),
      usedAt: json['usedAt'] != null ? DateTime.tryParse(json['usedAt']) : null,
      matchTitle: json['matchTitle'],
      sectorName: json['sectorName'],
      userFullName: json['userFullName'],
      avatarUrl: json['avatarUrl'],
      scheduledAt: json['scheduledAt'] != null ? DateTime.tryParse(json['scheduledAt']) : null,
      arenaName: json['arenaName'],
      arenaCity: json['arenaCity'],
    );
  }
}

class Booking {
  final String id;
  final String? userId;
  final String? matchId;
  final User? user;
  final Match match;
  final BookingStatus status;
  final DateTime? cancelDeadline;
  final String? notes;
  final DateTime createdAt;
  final Ticket? ticket;
  final AttendanceStatus attendanceStatus;

  Booking({
    required this.id,
    this.userId,
    this.matchId,
    this.user,
    required this.match,
    required this.status,
    this.cancelDeadline,
    this.notes,
    required this.createdAt,
    this.ticket,
    this.attendanceStatus = AttendanceStatus.unknown,
  });

  String get shortId => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  bool get canCancel {
    if (status != BookingStatus.pending && status != BookingStatus.confirmed) {
      return false;
    }
    if (cancelDeadline != null && DateTime.now().isAfter(cancelDeadline!)) {
      return false;
    }
    return true;
  }

  bool get isUpcoming {
    return match.scheduledAt.isAfter(DateTime.now()) &&
        (status == BookingStatus.pending || status == BookingStatus.confirmed);
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['userId'],
      matchId: json['matchId'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      match: Match.fromJson(json['match'] ?? {}),
      status: BookingStatus.fromString(json['status']),
      cancelDeadline: json['cancelDeadline'] != null ? DateTime.tryParse(json['cancelDeadline']) : null,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
      attendanceStatus: AttendanceStatus.fromString(json['attendance']?['status']),
    );
  }
}

class QrVerificationResult {
  final bool isValid;
  final bool isUsed;
  final Booking? booking;
  final String? message;

  QrVerificationResult({
    required this.isValid,
    required this.isUsed,
    this.booking,
    this.message,
  });

  factory QrVerificationResult.fromJson(Map<String, dynamic> json) {
    return QrVerificationResult(
      isValid: json['isValid'] ?? false,
      isUsed: json['isUsed'] ?? false,
      booking: json['booking'] != null ? Booking.fromJson(json['booking']) : null,
      message: json['message'],
    );
  }
}
