import Foundation

// MARK: - App Configuration

enum AppConfiguration {
    static var apiBaseURL: URL {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? "http://localhost:3000/api/v1"
        return URL(string: urlString)!
    }

    static var uploadsBaseURL: URL {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "UPLOADS_BASE_URL") as? String
            ?? ProcessInfo.processInfo.environment["UPLOADS_BASE_URL"]
            ?? "http://localhost:3000"
        return URL(string: urlString)!
    }

    static let clubName      = "ХК Сибирь"
    static let clubCity      = "Новосибирск"
    static let clubShortName = "Сибирь"
    static let appVersion    = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
}
