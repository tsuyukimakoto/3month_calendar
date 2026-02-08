import Foundation
import WidgetKit

struct HolidayCalendar {
    let dates: Set<String>

    func isHoliday(_ date: Date, calendar: Calendar) -> Bool {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        return dates.contains(key)
    }
}

final class HolidayStore {
    static let shared = HolidayStore()

    // Default Japan holiday calendar (public iCal).
    // https://calendar.google.com/calendar/ical/2bk907eqjut8imoorgq1qa4olc%40group.calendar.google.com/public/basic.ics
    private let defaultHolidayURL = URL(string: "https://calendar.google.com/calendar/ical/2bk907eqjut8imoorgq1qa4olc%40group.calendar.google.com/public/basic.ics")!

    private let cacheFolderName = "HolidayCache"
    private let refreshMarkerName = "holiday_refresh.json"

    private init() {}

    func loadCachedHolidays(years: [Int], calendar: Calendar) -> HolidayCalendar {
        var dates = Set<String>()
        for year in years {
            if let yearDates = readYearFile(year: year) {
                dates.formUnion(yearDates)
            }
        }
        return HolidayCalendar(dates: dates)
    }

    func shouldRefresh(referenceDate: Date, calendar: Calendar) -> Bool {
        let day = calendar.component(.day, from: referenceDate)
        guard day == 1 else { return false }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.dateFormat = "yyyy-MM"
        let monthKey = formatter.string(from: referenceDate)
        let last = readRefreshMarker()
        return last != monthKey
    }

    func markRefreshed(referenceDate: Date, calendar: Calendar) {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.dateFormat = "yyyy-MM"
        let monthKey = formatter.string(from: referenceDate)
        writeRefreshMarker(monthKey)
    }

    func fetchAndCache(years: [Int], calendar: Calendar, overrideURL: String) async -> HolidayCalendar? {
        do {
            let url = resolveURL(overrideURL)
            let (data, _) = try await URLSession.shared.data(from: url)
            let dates = parseHolidays(from: data, calendar: calendar)
            let grouped = groupDatesByYear(dates)
            for year in years {
                let values = grouped[year] ?? []
                writeYearFile(year: year, dates: values)
            }
            return HolidayCalendar(dates: dates)
        } catch {
            return nil
        }
    }

    private func resolveURL(_ overrideURL: String) -> URL {
        let trimmed = overrideURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), !trimmed.isEmpty {
            return url
        }
        return defaultHolidayURL
    }

    private func parseHolidays(from data: Data, calendar: Calendar) -> Set<String> {
        guard let content = String(data: data, encoding: .utf8) else { return [] }
        var dates = Set<String>()
        var currentDate: Date?

        for line in content.split(separator: "\n") {
            if line.hasPrefix("DTSTART") {
                let parts = line.split(separator: ":")
                guard let datePart = parts.last else { continue }
                let raw = String(datePart).trimmingCharacters(in: .whitespacesAndNewlines)
                if let date = parseICSDate(raw, calendar: calendar) {
                    currentDate = date
                }
            } else if line.hasPrefix("SUMMARY") {
                if let date = currentDate {
                    let formatter = DateFormatter()
                    formatter.calendar = calendar
                    formatter.locale = calendar.locale
                    formatter.dateFormat = "yyyy-MM-dd"
                    dates.insert(formatter.string(from: date))
                }
                currentDate = nil
            }
        }

        return dates
    }

    private func parseICSDate(_ value: String, calendar: Calendar) -> Date? {
        // Support DATE (yyyyMMdd) and DATE-TIME (yyyyMMdd'T'HHmmss'Z').
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        if value.contains("T") {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.date(from: value)
        } else {
            formatter.dateFormat = "yyyyMMdd"
            return formatter.date(from: value)
        }
    }

    private func groupDatesByYear(_ dates: Set<String>) -> [Int: [String]] {
        var result: [Int: [String]] = [:]
        for date in dates {
            let yearString = String(date.prefix(4))
            if let year = Int(yearString) {
                result[year, default: []].append(date)
            }
        }
        return result
    }

    private func cacheDirectory() -> URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = base.appendingPathComponent(cacheFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func yearFileURL(year: Int) -> URL? {
        cacheDirectory()?.appendingPathComponent("holidays_\(year).json")
    }

    private func refreshMarkerURL() -> URL? {
        cacheDirectory()?.appendingPathComponent(refreshMarkerName)
    }

    private func readYearFile(year: Int) -> Set<String>? {
        guard let url = yearFileURL(year: year),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String].self, from: data)
        else {
            return nil
        }
        return Set(decoded)
    }

    private func writeYearFile(year: Int, dates: [String]) {
        guard let url = yearFileURL(year: year) else { return }
        let sorted = dates.sorted()
        if let data = try? JSONEncoder().encode(sorted) {
            try? data.write(to: url)
        }
    }

    private func readRefreshMarker() -> String? {
        guard let url = refreshMarkerURL(),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return nil
        }
        return decoded["month"]
    }

    private func writeRefreshMarker(_ month: String) {
        guard let url = refreshMarkerURL() else { return }
        let payload = ["month": month]
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: url)
        }
    }
}
