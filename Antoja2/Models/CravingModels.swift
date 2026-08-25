import Foundation

enum ChatRole {
    case user
    case assistant
}

struct ChatMessage: Identifiable {
    let id: UUID
    let role: ChatRole
    let text: String
    let draft: CravingDraft?

    init(id: UUID = UUID(), role: ChatRole, text: String, draft: CravingDraft? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.draft = draft
    }
}

struct CravingAssumption: Identifiable, Equatable {
    let id: String
    let label: String
    let value: String
    let reason: String
    let isEditable: Bool

    var dictionary: [String: Any] {
        [
            "id": id,
            "label": label,
            "value": value,
            "reason": reason,
            "editable": isEditable
        ]
    }
}

struct CravingDraft: Identifiable, Equatable {
    let id: UUID
    let title: String
    let normalizedFoodName: String
    let portionText: String
    let estimatedCaloriesMin: Int
    let estimatedCaloriesMax: Int
    let assumptions: [CravingAssumption]
    let needsClarification: Bool
    let clarifyingQuestion: String
    let confidence: String
    let source: String

    init(
        id: UUID = UUID(),
        title: String,
        normalizedFoodName: String,
        portionText: String,
        estimatedCaloriesMin: Int,
        estimatedCaloriesMax: Int,
        assumptions: [CravingAssumption],
        needsClarification: Bool,
        clarifyingQuestion: String,
        confidence: String,
        source: String = "ai_estimate"
    ) {
        self.id = id
        self.title = title
        self.normalizedFoodName = normalizedFoodName
        self.portionText = portionText
        self.estimatedCaloriesMin = estimatedCaloriesMin
        self.estimatedCaloriesMax = estimatedCaloriesMax
        self.assumptions = assumptions
        self.needsClarification = needsClarification
        self.clarifyingQuestion = clarifyingQuestion
        self.confidence = confidence
        self.source = source
    }

    var calorieRangeText: String {
        guard estimatedCaloriesMax > 0 else { return "Por definir" }
        if estimatedCaloriesMin == estimatedCaloriesMax {
            return "≈ \(estimatedCaloriesMax) kcal"
        }
        return "\(estimatedCaloriesMin)–\(estimatedCaloriesMax) kcal"
    }

    var dictionary: [String: Any] {
        [
            "title": title,
            "normalizedFoodName": normalizedFoodName,
            "portionText": portionText,
            "estimatedCaloriesMin": estimatedCaloriesMin,
            "estimatedCaloriesMax": estimatedCaloriesMax,
            "assumptions": assumptions.map(\.dictionary),
            "needsClarification": needsClarification,
            "clarifyingQuestion": clarifyingQuestion,
            "confidence": confidence,
            "source": source
        ]
    }
}

enum CravingStatus: String {
    case pending
    case consumed
    case avoidedConfirmed = "avoided_confirmed"
}

struct Craving: Identifiable, Equatable {
    let id: String
    let title: String
    let portionText: String
    let estimatedCaloriesMin: Int
    let estimatedCaloriesMax: Int
    let createdAt: Date
    let followUpDueAt: Date
    let status: CravingStatus

    var calorieRangeText: String {
        if estimatedCaloriesMin == estimatedCaloriesMax {
            return "≈ \(estimatedCaloriesMax) kcal"
        }
        return "\(estimatedCaloriesMin)–\(estimatedCaloriesMax) kcal"
    }

    var isOverdue: Bool {
        status == .pending && followUpDueAt <= Date()
    }

    var estimatedCaloriesMidpoint: Int {
        (estimatedCaloriesMin + estimatedCaloriesMax) / 2
    }
}
