import Combine
import Foundation

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published private(set) var selectedWeek: WeeklyProgress
    @Published private(set) var chartWeeks: [WeeklyProgress] = []
    @Published private(set) var badges: [ProgressBadge] = []
    @Published private(set) var experiencePoints = 0
    @Published private(set) var checkInStreak = 0
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let repository: ProgressRepository
    private var selectedWeekStart: Date
    private var cravings: [ProgressCraving] = []
    private var cancellables = Set<AnyCancellable>()

    private static var limaCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.locale = Locale(identifier: "es_PE")
        calendar.timeZone = TimeZone(identifier: "America/Lima") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }

    init(userID: String) {
        let weekStart = Self.startOfWeek(containing: Date())
        selectedWeekStart = weekStart
        selectedWeek = Self.emptyWeek(starting: weekStart)
        repository = ProgressRepository(userID: userID)

        repository.$cravings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cravings in
                self?.cravings = cravings
                self?.recalculate()
            }
            .store(in: &cancellables)

        repository.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isLoading = $0 }
            .store(in: &cancellables)

        repository.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.errorMessage = $0 }
            .store(in: &cancellables)
    }

    var canGoToNextWeek: Bool {
        selectedWeekStart < Self.startOfWeek(containing: Date())
    }

    var canGoToPreviousWeek: Bool {
        guard let oldestDate = cravings.map(\.createdAt).min() else { return false }
        return Self.startOfWeek(containing: oldestDate) < selectedWeekStart
    }

    var level: Int {
        max(1, experiencePoints / 100 + 1)
    }

    var levelProgress: Double {
        Double(experiencePoints % 100) / 100
    }

    var pointsUntilNextLevel: Int {
        100 - (experiencePoints % 100)
    }

    var chartMaximum: Int {
        max(100, Int(Double(chartWeeks.map(\.estimatedAvoidedCalories).max() ?? 0) * 1.2))
    }

    func goToPreviousWeek() {
        guard canGoToPreviousWeek else { return }
        selectedWeekStart = Self.limaCalendar.date(byAdding: .weekOfYear, value: -1, to: selectedWeekStart)
            ?? selectedWeekStart
        recalculate()
    }

    func goToNextWeek() {
        guard canGoToNextWeek else { return }
        selectedWeekStart = Self.limaCalendar.date(byAdding: .weekOfYear, value: 1, to: selectedWeekStart)
            ?? selectedWeekStart
        recalculate()
    }

    func clearError() {
        errorMessage = nil
    }

    private func recalculate() {
        selectedWeek = makeWeek(starting: selectedWeekStart)
        chartWeeks = (0..<8).reversed().map { offset in
            let start = Self.limaCalendar.date(
                byAdding: .weekOfYear,
                value: -offset,
                to: selectedWeekStart
            ) ?? selectedWeekStart
            return makeWeek(starting: start)
        }

        let resolved = cravings.filter { $0.status != .pending }
        experiencePoints = resolved.count * 10
        checkInStreak = makeCheckInStreak()
        badges = makeBadges(resolved: resolved)
    }

    private func makeWeek(starting start: Date) -> WeeklyProgress {
        let end = Self.limaCalendar.date(byAdding: .day, value: 7, to: start)
            ?? start.addingTimeInterval(7 * 24 * 60 * 60)
        let weekCravings = cravings.filter { $0.createdAt >= start && $0.createdAt < end }
        let avoided = weekCravings
            .filter { $0.status == .avoidedConfirmed }
            .sorted { $0.createdAt > $1.createdAt }

        return WeeklyProgress(
            weekStart: start,
            weekEnd: end,
            cravings: weekCravings,
            avoidedCravings: avoided,
            avoidedCaloriesMin: avoided.reduce(0) { $0 + $1.estimatedCaloriesMin },
            avoidedCaloriesMax: avoided.reduce(0) { $0 + $1.estimatedCaloriesMax },
            estimatedAvoidedCalories: avoided.reduce(0) { total, craving in
                total + craving.estimatedAvoidedCalories
            },
            consumedCount: weekCravings.filter { $0.status == .consumed }.count,
            resolvedCount: weekCravings.filter { $0.status != .pending }.count,
            pendingCount: weekCravings.filter { $0.status == .pending }.count
        )
    }

    private func makeCheckInStreak() -> Int {
        var streak = 0
        let graceLimit = Date().addingTimeInterval(-48 * 60 * 60)

        for craving in cravings.sorted(by: { $0.createdAt > $1.createdAt }) {
            if craving.status == .pending {
                if craving.followUpDueAt < graceLimit { break }
                continue
            }
            streak += 1
        }
        return streak
    }

    private func makeBadges(resolved: [ProgressCraving]) -> [ProgressBadge] {
        let avoidedCount = resolved.filter { $0.status == .avoidedConfirmed }.count
        let activeWeeks = Set(resolved.map { Self.startOfWeek(containing: $0.createdAt) }).count
        let completedWeek = Dictionary(grouping: cravings) { Self.startOfWeek(containing: $0.createdAt) }
            .contains { weekStart, items in
                weekStart < Self.startOfWeek(containing: Date())
                    && !items.isEmpty
                    && items.allSatisfy { $0.status != .pending }
            }

        return [
            ProgressBadge(
                id: "first_check_in",
                title: "Primer paso",
                subtitle: "Completa tu primer seguimiento",
                systemImage: "sparkles",
                isUnlocked: !resolved.isEmpty
            ),
            ProgressBadge(
                id: "five_check_ins",
                title: "Constancia",
                subtitle: "Completa 5 seguimientos",
                systemImage: "checkmark.seal.fill",
                isUnlocked: resolved.count >= 5
            ),
            ProgressBadge(
                id: "ten_avoided",
                title: "Coleccionista",
                subtitle: "Reúne 10 decisiones evitadas",
                systemImage: "square.grid.2x2.fill",
                isUnlocked: avoidedCount >= 10
            ),
            ProgressBadge(
                id: "complete_week",
                title: "Todo al día",
                subtitle: "Cierra una semana sin pendientes",
                systemImage: "calendar.badge.checkmark",
                isUnlocked: completedWeek
            ),
            ProgressBadge(
                id: "four_weeks",
                title: "Un mes presente",
                subtitle: "Registra decisiones en 4 semanas",
                systemImage: "flame.fill",
                isUnlocked: activeWeeks >= 4
            )
        ]
    }

    private static func startOfWeek(containing date: Date) -> Date {
        limaCalendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? limaCalendar.startOfDay(for: date)
    }

    private static func emptyWeek(starting start: Date) -> WeeklyProgress {
        let end = limaCalendar.date(byAdding: .day, value: 7, to: start)
            ?? start.addingTimeInterval(7 * 24 * 60 * 60)
        return WeeklyProgress(
            weekStart: start,
            weekEnd: end,
            cravings: [],
            avoidedCravings: [],
            avoidedCaloriesMin: 0,
            avoidedCaloriesMax: 0,
            estimatedAvoidedCalories: 0,
            consumedCount: 0,
            resolvedCount: 0,
            pendingCount: 0
        )
    }
}
