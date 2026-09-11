import Foundation

enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}

enum APIEndpoint {
    // MARK: Auth
    case login(emailOrPhone: String, password: String)
    case register(email: String?, phone: String?, username: String,
                  firstName: String, lastName: String, password: String)
    case refresh(token: String)
    case logout
    case forgotPassword(emailOrPhone: String)

    // MARK: Profile
    case getMyProfile
    case updateProfile(firstName: String, lastName: String, city: String?, bio: String?)
    case uploadAvatar(imageData: Data)
    case deleteAvatar
    case getSocialLinks
    case addSocialLink(platform: String, url: String, label: String?)
    case updateSocialLink(id: String, platform: String, url: String, label: String?)
    case deleteSocialLink(id: String)

    // MARK: Matches
    case getMatches(filter: String?)
    case getMatch(id: String)
    case createMatch(body: [String: Any])
    case updateMatch(id: String, body: [String: Any])
    case deleteMatch(id: String)
    case getMatchParticipants(matchId: String)
    case exportMatchCSV(matchId: String)

    // MARK: Teams & Arenas
    case getTeams
    case createTeam(name: String, city: String?)
    case getArenas
    case createArena(name: String, city: String, address: String?)

    // MARK: Bookings
    case createBooking(matchId: String)
    case getMyBookings
    case getBooking(id: String)
    case cancelBooking(id: String)
    case getAllBookings(status: String?)
    case confirmBooking(id: String)
    case rejectBooking(id: String)
    case adminCancelBooking(id: String)

    // MARK: Tickets
    case getTicket(bookingId: String)
    case verifyQR(token: String)
    case markAttendedByQR(qrToken: String)

    // MARK: Attendance
    case markAttendance(bookingId: String, status: String)
    case getMatchAttendance(matchId: String)
    case bulkMarkAttendance(matchId: String, items: [[String: String]])

    // MARK: Stats
    case getMyStats
    case getUserStats(userId: String)
    case getAdminOverviewStats
    case getAdminMatchStats

    // MARK: Notifications
    case getNotifications
    case markAllNotificationsRead
    case updateFCMToken(token: String)
    case sendNotification(title: String, body: String, role: String?)

    // MARK: Users (Manager+)
    case getUsers(search: String?)
    case getUser(id: String)
    case updateUserRole(id: String, role: String)
    case updateUserStatus(id: String, isActive: Bool)

    // MARK: - Path
    var path: String {
        switch self {
        case .login:                    return "/auth/login"
        case .register:                 return "/auth/register"
        case .refresh:                  return "/auth/refresh"
        case .logout:                   return "/auth/logout"
        case .forgotPassword:           return "/auth/forgot-password"
        case .getMyProfile,
             .updateProfile:            return "/profile/me"
        case .uploadAvatar,
             .deleteAvatar:             return "/profile/me/avatar"
        case .getSocialLinks,
             .addSocialLink:            return "/profile/me/social-links"
        case .updateSocialLink(let id, _, _, _):  return "/profile/me/social-links/\(id)"
        case .deleteSocialLink(let id):           return "/profile/me/social-links/\(id)"
        case .getMatches:               return "/matches"
        case .getMatch(let id):         return "/matches/\(id)"
        case .createMatch:              return "/matches"
        case .updateMatch(let id, _):   return "/matches/\(id)"
        case .deleteMatch(let id):      return "/matches/\(id)"
        case .getMatchParticipants(let id): return "/matches/\(id)/participants"
        case .exportMatchCSV(let id):   return "/matches/\(id)/export-csv"
        case .getTeams, .createTeam:    return "/teams"
        case .getArenas, .createArena:  return "/arenas"
        case .createBooking:            return "/bookings"
        case .getMyBookings:            return "/bookings/my"
        case .getBooking(let id):       return "/bookings/\(id)"
        case .cancelBooking(let id):    return "/bookings/\(id)/cancel"
        case .getAllBookings:            return "/bookings"
        case .confirmBooking(let id):   return "/bookings/\(id)/confirm"
        case .rejectBooking(let id):    return "/bookings/\(id)/reject"
        case .adminCancelBooking(let id): return "/bookings/\(id)/admin-cancel"
        case .getTicket(let bid):       return "/tickets/\(bid)"
        case .verifyQR:                 return "/tickets/verify"
        case .markAttendedByQR:         return "/tickets/mark-attended"
        case .markAttendance:           return "/attendance/mark"
        case .getMatchAttendance(let id): return "/attendance/match/\(id)"
        case .bulkMarkAttendance(let id, _): return "/attendance/match/\(id)/bulk-mark"
        case .getMyStats:               return "/stats/my"
        case .getUserStats(let id):     return "/stats/user/\(id)"
        case .getAdminOverviewStats:    return "/stats/admin/overview"
        case .getAdminMatchStats:       return "/stats/admin/matches"
        case .getNotifications:         return "/notifications"
        case .markAllNotificationsRead: return "/notifications/read-all"
        case .updateFCMToken:           return "/notifications/fcm-token"
        case .sendNotification:         return "/notifications/send"
        case .getUsers:                 return "/users"
        case .getUser(let id):          return "/users/\(id)"
        case .updateUserRole(let id, _):   return "/users/\(id)/role"
        case .updateUserStatus(let id, _): return "/users/\(id)/status"
        }
    }

    // MARK: - HTTP Method
    var method: HTTPMethod {
        switch self {
        case .login, .register, .logout, .forgotPassword,
             .createBooking, .cancelBooking, .confirmBooking, .rejectBooking, .adminCancelBooking,
             .verifyQR, .markAttendedByQR, .markAttendance, .bulkMarkAttendance,
             .createMatch, .createTeam, .createArena, .addSocialLink,
             .sendNotification, .exportMatchCSV, .uploadAvatar:
            return .post
        case .getMyProfile, .getMatches, .getMatch, .getMyBookings, .getBooking,
             .getAllBookings, .getTicket, .getMatchAttendance, .getMyStats,
             .getUserStats, .getAdminOverviewStats, .getAdminMatchStats,
             .getNotifications, .getUsers, .getUser, .getTeams, .getArenas,
             .getSocialLinks, .getMatchParticipants:
            return .get
        case .updateProfile, .updateMatch, .updateSocialLink, .updateUserRole,
             .updateUserStatus, .markAllNotificationsRead, .updateFCMToken, .refresh:
            return .put
        case .deleteAvatar, .deleteMatch, .deleteSocialLink:
            return .delete
        }
    }

    // MARK: - Query Items
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getMatches(let f):    return f.map { [URLQueryItem(name: "filter", value: $0)] }
        case .getAllBookings(let s): return s.map { [URLQueryItem(name: "status", value: $0)] }
        case .getUsers(let s):
            guard let s, !s.isEmpty else { return nil }
            return [URLQueryItem(name: "search", value: s)]
        default: return nil
        }
    }

    // MARK: - Body
    var bodyData: Data? {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        switch self {
        case .login(let e, let p):
            return try? enc.encode(["emailOrPhone": e, "password": p])
        case .register(let email, let phone, let username, let fn, let ln, let pwd):
            var d: [String: String] = ["username": username, "firstName": fn, "lastName": ln, "password": pwd]
            if let email { d["email"] = email }
            if let phone { d["phone"] = phone }
            return try? enc.encode(d)
        case .refresh(let t):
            return try? enc.encode(["refreshToken": t])
        case .forgotPassword(let e):
            return try? enc.encode(["emailOrPhone": e])
        case .updateProfile(let fn, let ln, let city, let bio):
            var d: [String: String] = ["firstName": fn, "lastName": ln]
            if let city { d["city"] = city }
            if let bio  { d["bio"]  = bio  }
            return try? enc.encode(d)
        case .addSocialLink(let p, let u, let l):
            var d: [String: String] = ["platform": p, "url": u]
            if let l { d["label"] = l }
            return try? enc.encode(d)
        case .updateSocialLink(_, let p, let u, let l):
            var d: [String: String] = ["platform": p, "url": u]
            if let l { d["label"] = l }
            return try? enc.encode(d)
        case .createBooking(let id):
            return try? enc.encode(["matchId": id])
        case .verifyQR(let t):
            return try? enc.encode(["qrToken": t])
        case .markAttendedByQR(let t):
            return try? enc.encode(["qrToken": t])
        case .markAttendance(let bid, let s):
            return try? enc.encode(["bookingId": bid, "status": s])
        case .bulkMarkAttendance(_, let items):
            return try? JSONSerialization.data(withJSONObject: ["attendances": items])
        case .createMatch(let b), .updateMatch(_, let b):
            return try? JSONSerialization.data(withJSONObject: b)
        case .createTeam(let name, let city):
            var d: [String: String] = ["name": name]
            if let city { d["city"] = city }
            return try? enc.encode(d)
        case .createArena(let name, let city, let address):
            var d: [String: String] = ["name": name, "city": city]
            if let address { d["address"] = address }
            return try? enc.encode(d)
        case .updateUserRole(_, let r):
            return try? enc.encode(["role": r])
        case .updateUserStatus(_, let a):
            return try? JSONSerialization.data(withJSONObject: ["isActive": a])
        case .updateFCMToken(let t):
            return try? enc.encode(["fcmToken": t])
        case .sendNotification(let title, let body, let role):
            var d: [String: String] = ["title": title, "body": body]
            if let role { d["role"] = role }
            return try? enc.encode(d)
        default: return nil
        }
    }

    // MARK: - Auth Required
    var requiresAuth: Bool {
        switch self {
        case .login, .register, .forgotPassword: return false
        default: return true
        }
    }

    // MARK: - Multipart
    var isMultipart: Bool {
        if case .uploadAvatar = self { return true }
        return false
    }

    var multipartBody: (Data, String)? {
        guard case .uploadAvatar(let imageData) = self else { return nil }
        let boundary = "FanZone-\(UUID().uuidString)"
        var data = Data()
        let crlf = "\r\n"
        func append(_ s: String) { data.append(s.data(using: .utf8)!) }
        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\(crlf)")
        append("Content-Type: image/jpeg\(crlf)\(crlf)")
        data.append(imageData)
        append("\(crlf)--\(boundary)--\(crlf)")
        return (data, boundary)
    }
}
