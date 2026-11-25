//
//  ItineraryPagesTests.swift
//  wravelTests
//

import Foundation
import Testing
@testable import wravel

/// How the itinerary's days become the trip screen's pages: Before, the trip's own
/// days, then After.
struct ItineraryPagesTests {

    private func entry(_ id: String, _ kind: TripItemKind = .activity, _ phase: ItineraryPhase? = nil) -> ItineraryEntry {
        ItineraryEntry(item: TripItem(
            id: id, tripId: "t", kind: kind, title: id, displayTitle: id, notes: nil, tags: [],
            startsAtLocal: .now, startsAtUtc: nil, startTimezone: nil, endsAtLocal: nil, endsAtUtc: nil,
            endTimezone: nil, imageUrl: nil, place: nil, endPlace: nil, createdAt: .now, updatedAt: .now
        ), phase: phase)
    }

    private func day(_ date: String, _ number: Int, trip: String?, _ entries: [ItineraryEntry] = []) -> ItineraryDay {
        ItineraryDay(date: date, dayNumber: number, lodging: [], entries: entries, tripId: trip)
    }

    @Test func datesOutsideTheTripsGoToBeforeAndAfter() {
        let pages = ItineraryPages(days: [
            day("2026-11-20", -5, trip: nil, [entry("early dinner")]),
            day("2026-11-25", 0, trip: nil, [entry("drinks")]),
            day("2026-11-26", 1, trip: "t", [entry("parade")]),
            day("2026-11-27", 2, trip: nil),
            day("2026-11-28", 3, trip: "t"),
            day("2026-11-30", 5, trip: nil, [entry("brunch")]),
        ])

        #expect(pages.tripDays.map(\.dayNumber) == [1, 2, 3])
        #expect(pages.before.entries.map(\.item.id) == ["early dinner", "drinks"])
        #expect(pages.after.entries.map(\.item.id) == ["brunch"])
        #expect(pages.all.map(\.dayNumber) == [ItineraryDay.beforePageNumber, 1, 2, 3, ItineraryDay.afterPageNumber])
        // Each entry keeps its own date, and a page's date sits next to the trip.
        #expect(pages.before.entryDates["early dinner||"] == "2026-11-20")
        #expect(pages.before.date == "2026-11-25")
        #expect(pages.after.date == "2026-11-29")
    }

    @Test func aTransitTouchingTheOutsideIsShownWhole() {
        let pages = ItineraryPages(days: [
            day("2026-11-25", 0, trip: nil, [entry("red-eye", .transit, .departure)]),
            day("2026-11-26", 1, trip: "t", [entry("red-eye", .transit, .arrival), entry("parade")]),
        ])

        #expect(pages.before.entries.map(\.id) == ["red-eye|departure|", "red-eye|arrival|"])
        #expect(pages.before.entryDates["red-eye|arrival|"] == "2026-11-26")
        // The day it lands still shows the landing.
        #expect(pages.tripDays[0].entries.map(\.id) == ["red-eye|arrival|", "parade||"])
    }

    @Test func beforeHasTheEvesLodgingAndAfterHasNone() {
        let hotel = LodgingStay(item: entry("hotel", .lodging).item, phase: .checkIn)
        let checkout = LodgingStay(item: entry("hotel", .lodging).item, phase: .checkOut)
        let pages = ItineraryPages(days: [
            ItineraryDay(date: "2026-11-20", dayNumber: -5, lodging: [LodgingStay(item: entry("motel", .lodging).item, phase: .staying)], entries: [], tripId: nil),
            ItineraryDay(date: "2026-11-25", dayNumber: 0, lodging: [hotel], entries: [], tripId: nil),
            day("2026-11-26", 1, trip: "t"),
            ItineraryDay(date: "2026-11-27", dayNumber: 2, lodging: [checkout], entries: [], tripId: nil),
        ])

        #expect(pages.before.lodging.map(\.item.id) == ["hotel"])
        #expect(pages.after.lodging.isEmpty)
    }

    @Test func withoutTripIdsEveryDateIsATripDay() {
        let pages = ItineraryPages(days: [
            day("2026-11-26", 1, trip: nil, [entry("parade")]),
            day("2026-11-27", 2, trip: nil),
        ])

        #expect(pages.tripDays.count == 2)
        #expect(pages.before.entries.isEmpty)
        #expect(pages.after.entries.isEmpty)
    }
}
