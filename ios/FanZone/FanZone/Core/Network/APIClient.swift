import Foundation

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, String)
    case unauthorized
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Неверный адрес запроса"
        case .noData:               return "Сервер не вернул данные"
        case .decodingError(let e): return "Ошибка разбора данных: \(e.localizedDescription)"
        case .serverError(_, let m): return m
        case .unauthorized:         return "Необходима авторизация"
        case .networkUnavailable:   return "Нет соединения с сервером"
        }
    }
}

// MARK: - API Error Response

private struct APIErrorResponse: Decodable {
    let error: String?
    let message: String?
    var text: String { error ?? message ?? "Неизвестная ошибка" }
}

private struct EmptyResponse: Decodable {}

// MARK: - API Client

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let session = URLSession.shared

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            // Try multiple formats
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: s) { return date }
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(
                in: c, debugDescription: "Cannot parse date: \(s)"
            )
        }
        return d
    }()

    // MARK: - Public Methods

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        do {
            return try await perform(endpoint)
        } catch NetworkError.unauthorized {
            try await refreshToken()
            return try await perform(endpoint)
        }
    }

    func requestEmpty(_ endpoint: APIEndpoint) async throws {
        let _: EmptyResponse = try await request(endpoint)
    }

    func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        let req = try makeRequest(endpoint)
        do {
            let (data, response) = try await session.data(for: req)
            try validate(response, data: data)
            return data
        } catch let e as NetworkError { throw e }
        catch { throw NetworkError.networkUnavailable }
    }

    // MARK: - Private

    private func perform<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let req = try makeRequest(endpoint)
        do {
            let (data, response) = try await session.data(for: req)
            try validate(response, data: data)
            return try decoder.decode(T.self, from: data)
        } catch let e as NetworkError { throw e }
        catch let e as DecodingError { throw NetworkError.decodingError(e) }
        catch { throw NetworkError.networkUnavailable }
    }

    private func makeRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        let base = AppConfiguration.apiBaseURL.absoluteString
        guard var comps = URLComponents(string: base + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        if let qi = endpoint.queryItems, !qi.isEmpty { comps.queryItems = qi }
        guard let url = comps.url else { throw NetworkError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod  = endpoint.method.rawValue
        req.timeoutInterval = 30

        if endpoint.requiresAuth, let token = KeychainManager.shared.getAccessToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if endpoint.isMultipart, let (body, boundary) = endpoint.multipartBody {
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        } else if let body = endpoint.bodyData {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }
        return req
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.networkUnavailable
        }
        if http.statusCode == 401 { throw NetworkError.unauthorized }
        guard (200...299).contains(http.statusCode) else {
            let msg = (try? decoder.decode(APIErrorResponse.self, from: data))?.text
                   ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw NetworkError.serverError(http.statusCode, msg)
        }
    }

    private func refreshToken() async throws {
        guard let refresh = KeychainManager.shared.getRefreshToken() else {
            throw NetworkError.unauthorized
        }
        let resp: AuthResponse = try await perform(.refresh(token: refresh))
        KeychainManager.shared.saveAccessToken(resp.accessToken)
        if let r = resp.refreshToken { KeychainManager.shared.saveRefreshToken(r) }
    }
}
