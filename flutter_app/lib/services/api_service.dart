import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/booking.dart';
import '../models/match.dart';
import '../models/stats.dart';
import '../models/user.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await StorageService.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response, Future<dynamic> Function() retry) async {
    if (response.statusCode == 401) {
      // Try refresh
      final refreshed = await _refreshToken();
      if (refreshed) {
        return await retry();
      } else {
        await StorageService.clearAll();
        throw ApiException(401, 'Сессия истекла. Пожалуйста, войдите снова.');
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    String errorMessage = 'Ошибка ${response.statusCode}';
    try {
      final errBody = jsonDecode(utf8.decode(response.bodyBytes));
      errorMessage = errBody['error'] ?? errBody['message'] ?? errorMessage;
    } catch (_) {}

    throw ApiException(response.statusCode, errorMessage);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        final newAccess = data['accessToken'];
        final newRefresh = data['refreshToken'];
        if (newAccess != null) {
          await StorageService.saveTokens(newAccess, newRefresh);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // MARK: - Auth
  Future<AuthResponse> login(String emailOrPhone, String password) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({'emailOrPhone': emailOrPhone, 'password': password}),
    );
    final data = await _handleResponse(response, () => login(emailOrPhone, password));
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> register({
    String? email,
    String? phone,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/register');
    final response = await http.post(
      url,
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
      }),
    );
    final data = await _handleResponse(response, () => register(
      email: email, phone: phone, username: username, firstName: firstName, lastName: lastName, password: password
    ));
    return AuthResponse.fromJson(data);
  }

  Future<void> forgotPassword(String emailOrPhone) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/forgot-password');
    final response = await http.post(
      url,
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({'emailOrPhone': emailOrPhone}),
    );
    await _handleResponse(response, () => forgotPassword(emailOrPhone));
  }

  Future<void> logout() async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/logout');
      await http.post(url, headers: await _getHeaders());
    } catch (_) {}
  }

  // MARK: - Profile
  Future<User> getMyProfile() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/profile/me');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getMyProfile());
    return User.fromJson(data);
  }

  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
    String? city,
    String? bio,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/profile/me');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        if (city != null) 'city': city,
        if (bio != null) 'bio': bio,
      }),
    );
    final data = await _handleResponse(response, () => updateProfile(
      firstName: firstName, lastName: lastName, city: city, bio: bio
    ));
    return UserProfile.fromJson(data);
  }

  Future<List<SocialLink>> getSocialLinks() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/profile/me/social-links');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getSocialLinks()) as List;
    return data.map((e) => SocialLink.fromJson(e)).toList();
  }

  Future<SocialLink> addSocialLink(String platform, String linkUrl, String? label) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/profile/me/social-links');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'platform': platform,
        'url': linkUrl,
        if (label != null) 'label': label,
      }),
    );
    final data = await _handleResponse(response, () => addSocialLink(platform, linkUrl, label));
    return SocialLink.fromJson(data);
  }

  Future<void> deleteSocialLink(String id) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/profile/me/social-links/$id');
    final response = await http.delete(url, headers: await _getHeaders());
    await _handleResponse(response, () => deleteSocialLink(id));
  }

  // MARK: - Matches
  Future<List<Match>> getMatches({String? filter}) async {
    final query = filter != null ? '?filter=$filter' : '';
    final url = Uri.parse('${AppConfig.apiBaseUrl}/matches$query');
    final response = await http.get(url, headers: await _getHeaders(requiresAuth: false));
    final data = await _handleResponse(response, () => getMatches(filter: filter)) as List;
    return data.map((e) => Match.fromJson(e)).toList();
  }

  Future<Match> getMatch(String id) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/matches/$id');
    final response = await http.get(url, headers: await _getHeaders(requiresAuth: false));
    final data = await _handleResponse(response, () => getMatch(id));
    return Match.fromJson(data);
  }

  Future<List<MatchParticipant>> getMatchParticipants(String matchId) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/matches/$matchId/participants');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getMatchParticipants(matchId)) as List;
    return data.map((e) => MatchParticipant.fromJson(e)).toList();
  }

  Future<Match> createMatch(Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/matches');
    final response = await http.post(url, headers: await _getHeaders(), body: jsonEncode(body));
    final data = await _handleResponse(response, () => createMatch(body));
    return Match.fromJson(data);
  }

  Future<void> deleteMatch(String id) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/matches/$id');
    final response = await http.delete(url, headers: await _getHeaders());
    await _handleResponse(response, () => deleteMatch(id));
  }

  // MARK: - Bookings
  Future<Booking> createBooking(String matchId, [String? notes]) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/bookings');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'matchId': matchId, if (notes != null) 'notes': notes}),
    );
    final data = await _handleResponse(response, () => createBooking(matchId, notes));
    return Booking.fromJson(data);
  }

  Future<List<Booking>> getMyBookings() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/bookings/my');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getMyBookings()) as List;
    return data.map((e) => Booking.fromJson(e)).toList();
  }

  Future<void> cancelBooking(String id) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/bookings/$id/cancel');
    final response = await http.post(url, headers: await _getHeaders());
    await _handleResponse(response, () => cancelBooking(id));
  }

  Future<List<Booking>> getAllBookings({String? status, String? matchId}) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (matchId != null) params.add('matchId=$matchId');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';

    final url = Uri.parse('${AppConfig.apiBaseUrl}/bookings$query');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getAllBookings(status: status, matchId: matchId)) as List;
    return data.map((e) => Booking.fromJson(e)).toList();
  }

  Future<Booking> confirmBooking(String id) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/bookings/$id/confirm');
    final response = await http.post(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => confirmBooking(id));
    return Booking.fromJson(data);
  }

  Future<void> rejectBooking(String id) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/bookings/$id/reject');
    final response = await http.post(url, headers: await _getHeaders());
    await _handleResponse(response, () => rejectBooking(id));
  }

  // MARK: - Tickets & QR
  Future<Ticket> getTicket(String bookingId) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/tickets/$bookingId');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getTicket(bookingId));
    return Ticket.fromJson(data);
  }

  Future<QrVerificationResult> verifyQR(String qrToken) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/tickets/verify');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'qrToken': qrToken}),
    );
    final data = await _handleResponse(response, () => verifyQR(qrToken));
    return QrVerificationResult.fromJson(data);
  }

  Future<void> markAttendedByQR(String qrToken) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/tickets/mark-attended');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'qrToken': qrToken}),
    );
    await _handleResponse(response, () => markAttendedByQR(qrToken));
  }

  Future<void> markAttendance(String bookingId, String status) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/attendance/mark');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'bookingId': bookingId, 'status': status}),
    );
    await _handleResponse(response, () => markAttendance(bookingId, status));
  }

  // MARK: - Stats
  Future<UserStats> getMyStats() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/stats/my');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getMyStats());
    return UserStats.fromJson(data);
  }

  Future<UserStats> getUserStats(String userId) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/stats/user/$userId');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getUserStats(userId));
    return UserStats.fromJson(data);
  }

  Future<AdminOverviewStats> getAdminOverviewStats() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/stats/admin/overview');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getAdminOverviewStats());
    return AdminOverviewStats.fromJson(data);
  }

  Future<List<AdminMatchStats>> getAdminMatchStats() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/stats/admin/matches');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getAdminMatchStats()) as List;
    return data.map((e) => AdminMatchStats.fromJson(e)).toList();
  }

  // MARK: - Users (Manager/Admin)
  Future<List<User>> getUsers({String? search}) async {
    final query = search != null && search.isNotEmpty ? '?search=$search' : '';
    final url = Uri.parse('${AppConfig.apiBaseUrl}/users$query');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getUsers(search: search)) as List;
    return data.map((e) => User.fromJson(e)).toList();
  }

  Future<void> updateUserRole(String userId, String role) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/users/$userId/role');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'role': role}),
    );
    await _handleResponse(response, () => updateUserRole(userId, role));
  }

  // MARK: - Teams & Arenas
  Future<List<Team>> getTeams() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/teams');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getTeams()) as List;
    return data.map((e) => Team.fromJson(e)).toList();
  }

  Future<List<Arena>> getArenas() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/arenas');
    final response = await http.get(url, headers: await _getHeaders());
    final data = await _handleResponse(response, () => getArenas()) as List;
    return data.map((e) => Arena.fromJson(e)).toList();
  }
}
