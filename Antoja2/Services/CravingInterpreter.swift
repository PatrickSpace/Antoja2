import FirebaseFunctions
import Foundation

protocol CravingInterpreting {
    func interpret(message: String, previousDraft: CravingDraft?) async throws -> CravingDraft
}

enum CravingInterpreterError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "La IA devolvió una respuesta incompleta. Intenta describir el antojo otra vez."
    }
}

final class FirebaseCravingInterpreter: CravingInterpreting {
    private let functions = Functions.functions(region: "southamerica-west1")

    func interpret(message: String, previousDraft: CravingDraft?) async throws -> CravingDraft {
        var payload: [String: Any] = ["message": message]
        if let previousDraft {
            payload["previousDraft"] = previousDraft.dictionary
        }

        let result = try await functions.httpsCallable("interpretCraving").call(payload)
        guard let data = result.data as? [String: Any] else {
            throw CravingInterpreterError.invalidResponse
        }

        return try parse(data)
    }

    private func parse(_ data: [String: Any]) throws -> CravingDraft {
        guard
            let title = data["title"] as? String,
            let normalizedFoodName = data["normalizedFoodName"] as? String,
            let portionText = data["portionText"] as? String,
            let minCalories = number(data["estimatedCaloriesMin"]),
            let maxCalories = number(data["estimatedCaloriesMax"]),
            let needsClarification = data["needsClarification"] as? Bool,
            let clarifyingQuestion = data["clarifyingQuestion"] as? String,
            let confidence = data["confidence"] as? String
        else {
            throw CravingInterpreterError.invalidResponse
        }

        let assumptionsData = data["assumptions"] as? [[String: Any]] ?? []
        let assumptions = assumptionsData.compactMap { item -> CravingAssumption? in
            guard
                let id = item["id"] as? String,
                let label = item["label"] as? String,
                let value = item["value"] as? String,
                let reason = item["reason"] as? String
            else { return nil }

            return CravingAssumption(
                id: id,
                label: label,
                value: value,
                reason: reason,
                isEditable: item["editable"] as? Bool ?? true
            )
        }

        return CravingDraft(
            title: title,
            normalizedFoodName: normalizedFoodName,
            portionText: portionText,
            estimatedCaloriesMin: minCalories,
            estimatedCaloriesMax: maxCalories,
            assumptions: assumptions,
            needsClarification: needsClarification,
            clarifyingQuestion: clarifyingQuestion,
            confidence: confidence,
            source: data["source"] as? String ?? "ai_estimate"
        )
    }

    private func number(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }
}

struct PreviewCravingInterpreter: CravingInterpreting {
    func interpret(message: String, previousDraft: CravingDraft?) async throws -> CravingDraft {
        CravingDraft(
            title: "¼ de pollo a la brasa",
            normalizedFoodName: "pollo a la brasa",
            portionText: "1/4 de pollo",
            estimatedCaloriesMin: 480,
            estimatedCaloriesMax: 620,
            assumptions: [
                CravingAssumption(
                    id: "skin",
                    label: "Piel",
                    value: "Incluida",
                    reason: "Es la presentación más habitual.",
                    isEditable: true
                ),
                CravingAssumption(
                    id: "sides",
                    label: "Acompañamientos",
                    value: "Sin papas ni salsas",
                    reason: "No fueron mencionados.",
                    isEditable: true
                )
            ],
            needsClarification: false,
            clarifyingQuestion: "",
            confidence: "medium",
            source: "preview"
        )
    }
}
