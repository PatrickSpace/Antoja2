import Foundation

struct ProgressCraving: Identifiable, Equatable {
    let id: String
    let title: String
    let portionText: String
    let estimatedCaloriesMin: Int
    let estimatedCaloriesMax: Int
    let estimatedAvoidedCalories: Int
    let estimatedConsumedCalories: Int
    let createdAt: Date
    let followUpDueAt: Date
    let outcomeResolvedAt: Date?
    let status: CravingStatus

    var calorieRangeText: String {
        if estimatedCaloriesMin == estimatedCaloriesMax {
            return "≈ \(estimatedCaloriesMax) kcal"
        }
        return "\(estimatedCaloriesMin)–\(estimatedCaloriesMax) kcal"
    }

    var foodSymbol: String {
        let normalizedTitle = title.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "es_PE")
        )

        if normalizedTitle.contains("cafe") || normalizedTitle.contains("bebida") {
            return "cup.and.saucer.fill"
        }
        if normalizedTitle.contains("helado") || normalizedTitle.contains("postre") {
            return "birthday.cake.fill"
        }
        if normalizedTitle.contains("pollo") {
            return "bird.fill"
        }
        return "fork.knife.circle.fill"
    }
}

struct WeeklyProgress: Identifiable, Equatable {
    let weekStart: Date
    let weekEnd: Date
    let cravings: [ProgressCraving]
    let avoidedCravings: [ProgressCraving]
    let avoidedCaloriesMin: Int
    let avoidedCaloriesMax: Int
    let estimatedAvoidedCalories: Int
    let consumedCount: Int
    let resolvedCount: Int
    let pendingCount: Int

    var id: Date { weekStart }

    var avoidedCaloriesRangeText: String {
        guard avoidedCaloriesMax > 0 else { return "Sin calorías evitadas todavía" }
        if avoidedCaloriesMin == avoidedCaloriesMax {
            return "≈ \(avoidedCaloriesMax) kcal"
        }
        return "Rango \(avoidedCaloriesMin)–\(avoidedCaloriesMax) kcal"
    }
}

struct ProgressBadge: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let isUnlocked: Bool
}
