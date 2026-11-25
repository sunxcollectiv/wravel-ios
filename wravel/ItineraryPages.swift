//
//  ItineraryPages.swift
//  wravel
//

import Foundation

/// The side of the trip's dates a page collects, for the Before and After pages.
enum ItinerarySide {
    case before
    case after

    var label: String {
        switch self {
        case .before: "Before"
        case .after: "After"
        }
    }
}

/// The itinerary as the trip screen pages through it: a Before page, the trip's own
/// days, then an After page.
///
/// The trip's days run from the first date one of the group's trips covers to the
/// last (gap days and uncovered days between trips included, as the server sends
/// them). Everything the server puts on a date before or after that, whatever the
/// date, is gathered onto the Before or After page instead of a page per day. A
/// transit that touches one of those dates is shown there in full, every leg and
/// end of it, even the end that lands within the trip.
struct ItineraryPages {
    let before: ItineraryDay
    let tripDays: [ItineraryDay]
    let after: ItineraryDay

    /// Every page in order.
    var all: [ItineraryDay] { [before] + tripDays + [after] }

    init(days: [ItineraryDay]) {
        // A server that doesn't say which trip a date is on: every date is a trip day.
        guard let first = days.firstIndex(where: { $0.tripId != nil }),
              let last = days.lastIndex(where: { $0.tripId != nil }) else {
            tripDays = days
            before = Self.page(.before, outside: [], all: days, date: days.first.flatMap { Self.shift($0.date, by: -1) })
            after = Self.page(.after, outside: [], all: days, date: days.last.flatMap { Self.shift($0.date, by: 1) })
            return
        }
        tripDays = Array(days[first...last])
        before = Self.page(.before, outside: Array(days[..<first]), all: days, date: Self.shift(days[first].date, by: -1))
        after = Self.page(.after, outside: Array(days[(last + 1)...]), all: days, date: Self.shift(days[last].date, by: 1))
    }

    /// One side's page: each item on the `outside` dates, in the order they come up,
    /// a transit with all its entries from `all`, anything else with just its entries
    /// on those dates. `date` is the date next to the trip on that side, for an item
    /// added from the page.
    private static func page(_ side: ItinerarySide, outside: [ItineraryDay], all: [ItineraryDay], date: String?) -> ItineraryDay {
        var order: [String] = []
        var entriesByItem: [String: [(date: String, entry: ItineraryEntry)]] = [:]
        for day in outside {
            for entry in day.entries {
                let id = entry.item.id
                if entriesByItem[id] == nil { order.append(id) }
                if entry.item.kind != .transit {
                    entriesByItem[id, default: []].append((day.date, entry))
                } else if entriesByItem[id] == nil {
                    // The whole journey, from wherever its entries fall.
                    entriesByItem[id] = all.flatMap { d in
                        d.entries.filter { $0.item.id == id }.map { (d.date, $0) }
                    }
                }
            }
        }
        let flattened = order.flatMap { entriesByItem[$0] ?? [] }
        return ItineraryDay(
            date: date ?? outside.first?.date ?? "",
            dayNumber: side == .before ? ItineraryDay.beforePageNumber : ItineraryDay.afterPageNumber,
            lodging: [],
            entries: flattened.map(\.entry),
            side: side,
            entryDates: Dictionary(flattened.map { ($0.entry.id, $0.date) }, uniquingKeysWith: { first, _ in first })
        )
    }

    /// The "yyyy-MM-dd" date `days` away from `date`.
    private static func shift(_ date: String, by days: Int) -> String? {
        guard let parsed = isoDate.date(from: date),
              let moved = Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: parsed) else { return nil }
        return isoDate.string(from: moved)
    }

    fileprivate static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension ItineraryDay {
    /// The Before and After pages' stand-in day numbers, clear of any real day's.
    static let beforePageNumber = Int.min
    static let afterPageNumber = Int.max

    /// The calendar date an entry on a Before or After page falls on, which the page
    /// itself doesn't have one of.
    func date(of entry: ItineraryEntry) -> Date? {
        entryDates[entry.id].flatMap { ItineraryPages.isoDate.date(from: $0) }
    }
}
