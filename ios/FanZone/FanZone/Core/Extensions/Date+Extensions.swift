import Foundation

extension Date {
    private static let ruLocale = Locale(identifier: "ru_RU")

    var ruDateTimeString: String {
        let f = DateFormatter()
        f.locale = Self.ruLocale
        f.dateFormat = "d MMMM 'в' HH:mm"
        return f.string(from: self)
    }

    var ruDateString: String {
        let f = DateFormatter()
        f.locale = Self.ruLocale
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: self)
    }

    var ruShortDateString: String {
        let f = DateFormatter()
        f.locale = Self.ruLocale
        f.dateFormat = "d MMMM"
        return f.string(from: self)
    }

    var ruTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }

    var ruDayMonthYearString: String {
        let f = DateFormatter()
        f.locale = Self.ruLocale
        f.dateFormat = "dd.MM.yyyy"
        return f.string(from: self)
    }

    var isUpcoming: Bool { self > Date() }
    var isPast:     Bool { self < Date() }

    func timeUntilString() -> String {
        let diff = self.timeIntervalSince(Date())
        if diff < 0 { return "Уже прошло" }
        let days  = Int(diff / 86400)
        let hours = Int((diff.truncatingRemainder(dividingBy: 86400)) / 3600)
        if days > 0 { return "Через \(days) \(days.dayWord())" }
        if hours > 0 { return "Через \(hours) ч" }
        return "Скоро"
    }
}

private extension Int {
    func dayWord() -> String {
        let mod = self % 100
        if (11...14).contains(mod) { return "дней" }
        switch mod % 10 {
        case 1:  return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
    }
}
