import Combine
import FirebaseFirestore
import Foundation

@MainActor
final class CravingRepository: ObservableObject {
    @Published private(set) var pendingCravings: [Craving] = []
    @Published private(set) var errorMessage: String?

    private let userID: String
    private let database: Firestore
    private var listener: ListenerRegistration?

    init(userID: String, database: Firestore = Firestore.firestore()) {
        self.userID = userID
        self.database = database
        observePendingCravings()
    }

    deinit {
        listener?.remove()
    }

    func createPending(from draft: CravingDraft) async throws -> Craving {
        let document = cravingsCollection.document()
        let now = Date()
        let followUpDate = now.addingTimeInterval(4 * 60 * 60)

        var data = draft.dictionary
        data.merge([
            "status": CravingStatus.pending.rawValue,
            "createdAt": Timestamp(date: now),
            "followUpDueAt": Timestamp(date: followUpDate),
            "estimatedConsumedCalories": 0,
            "estimatedAvoidedCalories": 0
        ]) { _, new in new }

        try await document.setData(data)

        return Craving(
            id: document.documentID,
            title: draft.title,
            portionText: draft.portionText,
            estimatedCaloriesMin: draft.estimatedCaloriesMin,
            estimatedCaloriesMax: draft.estimatedCaloriesMax,
            createdAt: now,
            followUpDueAt: followUpDate,
            status: .pending
        )
    }

    func markConsumed(_ craving: Craving) async throws {
        try await updateOutcome(
            craving,
            status: .consumed,
            consumedCalories: midpoint(for: craving),
            avoidedCalories: 0
        )
    }

    func markAvoided(_ craving: Craving) async throws {
        try await updateOutcome(
            craving,
            status: .avoidedConfirmed,
            consumedCalories: 0,
            avoidedCalories: midpoint(for: craving)
        )
    }

    private var cravingsCollection: CollectionReference {
        database.collection("users").document(userID).collection("cravings")
    }

    private func observePendingCravings() {
        listener = cravingsCollection
            .whereField("status", isEqualTo: CravingStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    Task { @MainActor in self.errorMessage = error.localizedDescription }
                    return
                }

                let cravings = snapshot?.documents.compactMap(Self.makeCraving) ?? []
                Task { @MainActor in
                    self.pendingCravings = cravings.sorted { $0.createdAt > $1.createdAt }
                    self.errorMessage = nil
                }
            }
    }

    private func updateOutcome(
        _ craving: Craving,
        status: CravingStatus,
        consumedCalories: Int,
        avoidedCalories: Int
    ) async throws {
        try await cravingsCollection.document(craving.id).updateData([
            "status": status.rawValue,
            "outcomeResolvedAt": FieldValue.serverTimestamp(),
            "estimatedConsumedCalories": consumedCalories,
            "estimatedAvoidedCalories": avoidedCalories
        ])
    }

    private func midpoint(for craving: Craving) -> Int {
        craving.estimatedCaloriesMidpoint
    }

    private static func makeCraving(_ document: QueryDocumentSnapshot) -> Craving? {
        let data = document.data()
        guard
            let title = data["title"] as? String,
            let portionText = data["portionText"] as? String,
            let minCalories = (data["estimatedCaloriesMin"] as? NSNumber)?.intValue,
            let maxCalories = (data["estimatedCaloriesMax"] as? NSNumber)?.intValue,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let followUpDueAt = (data["followUpDueAt"] as? Timestamp)?.dateValue(),
            let statusValue = data["status"] as? String,
            let status = CravingStatus(rawValue: statusValue)
        else { return nil }

        return Craving(
            id: document.documentID,
            title: title,
            portionText: portionText,
            estimatedCaloriesMin: minCalories,
            estimatedCaloriesMax: maxCalories,
            createdAt: createdAt,
            followUpDueAt: followUpDueAt,
            status: status
        )
    }
}
