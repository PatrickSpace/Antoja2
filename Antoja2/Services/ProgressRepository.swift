import Combine
import FirebaseFirestore
import Foundation

@MainActor
final class ProgressRepository: ObservableObject {
    @Published private(set) var cravings: [ProgressCraving] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = true

    private let database: Firestore
    private let userID: String
    private var listener: ListenerRegistration?

    init(userID: String, database: Firestore = Firestore.firestore()) {
        self.userID = userID
        self.database = database
        observeHistory()
    }

    deinit {
        listener?.remove()
    }

    private func observeHistory() {
        listener = database
            .collection("users")
            .document(userID)
            .collection("cravings")
            .order(by: "createdAt", descending: true)
            .limit(to: 500)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                    return
                }

                let cravings = snapshot?.documents.compactMap(Self.makeCraving) ?? []
                Task { @MainActor in
                    self.cravings = cravings
                    self.errorMessage = nil
                    self.isLoading = false
                }
            }
    }

    private static func makeCraving(_ document: QueryDocumentSnapshot) -> ProgressCraving? {
        let data = document.data()
        guard
            let title = data["title"] as? String,
            let portionText = data["portionText"] as? String,
            let minCalories = (data["estimatedCaloriesMin"] as? NSNumber)?.intValue,
            let maxCalories = (data["estimatedCaloriesMax"] as? NSNumber)?.intValue,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let statusValue = data["status"] as? String,
            let status = CravingStatus(rawValue: statusValue)
        else { return nil }

        let midpoint = (minCalories + maxCalories) / 2
        let avoidedCalories = (data["estimatedAvoidedCalories"] as? NSNumber)?.intValue
            ?? (status == .avoidedConfirmed ? midpoint : 0)
        let consumedCalories = (data["estimatedConsumedCalories"] as? NSNumber)?.intValue
            ?? (status == .consumed ? midpoint : 0)

        return ProgressCraving(
            id: document.documentID,
            title: title,
            portionText: portionText,
            estimatedCaloriesMin: minCalories,
            estimatedCaloriesMax: maxCalories,
            estimatedAvoidedCalories: avoidedCalories,
            estimatedConsumedCalories: consumedCalories,
            createdAt: createdAt,
            followUpDueAt: (data["followUpDueAt"] as? Timestamp)?.dateValue()
                ?? createdAt.addingTimeInterval(4 * 60 * 60),
            outcomeResolvedAt: (data["outcomeResolvedAt"] as? Timestamp)?.dateValue(),
            status: status
        )
    }
}
