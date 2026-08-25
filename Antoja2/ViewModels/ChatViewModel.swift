import Combine
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var inputText = ""
    @Published private(set) var messages: [ChatMessage]
    @Published private(set) var pendingCravings: [Craving] = []
    @Published private(set) var activeDraft: CravingDraft?
    @Published private(set) var isProcessing = false
    @Published private(set) var isSaving = false
    @Published private(set) var isWaitingForCorrection = false
    @Published var errorMessage: String?

    private let interpreter: CravingInterpreting
    private let repository: CravingRepository
    private var cancellables = Set<AnyCancellable>()

    init(userID: String, interpreter: CravingInterpreting? = nil) {
        self.interpreter = interpreter ?? FirebaseCravingInterpreter()
        self.repository = CravingRepository(userID: userID)
        self.messages = [
            ChatMessage(
                role: .assistant,
                text: "Hola. Cuéntame qué se te antoja y lo ordenamos juntos antes de registrarlo."
            )
        ]

        repository.$pendingCravings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pendingCravings = $0 }
            .store(in: &cancellables)

        repository.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.errorMessage = $0 }
            .store(in: &cancellables)
    }

    func sendCurrentMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isProcessing else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, text: message))
        isProcessing = true
        errorMessage = nil

        let previousDraft = activeDraft
        Task {
            do {
                let draft = try await interpreter.interpret(
                    message: message,
                    previousDraft: previousDraft
                )
                activeDraft = draft

                if draft.needsClarification {
                    isWaitingForCorrection = true
                    messages.append(
                        ChatMessage(
                            role: .assistant,
                            text: draft.clarifyingQuestion.isEmpty
                                ? "Me falta un detalle para estimarlo. ¿Puedes contarme un poco más?"
                                : draft.clarifyingQuestion
                        )
                    )
                } else {
                    isWaitingForCorrection = false
                    messages.append(
                        ChatMessage(
                            role: .assistant,
                            text: "Esto es lo que entendí. Revisa especialmente los supuestos antes de registrarlo.",
                            draft: draft
                        )
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
                messages.append(
                    ChatMessage(
                        role: .assistant,
                        text: chatMessage(for: error)
                    )
                )
            }
            isProcessing = false
        }
    }

    func askToChange(_ draft: CravingDraft) {
        guard activeDraft?.id == draft.id else { return }
        isWaitingForCorrection = true
        messages.append(
            ChatMessage(
                role: .assistant,
                text: "Claro. Escríbeme qué supuesto, porción o ingrediente debo cambiar."
            )
        )
    }

    func register(_ draft: CravingDraft) {
        guard activeDraft?.id == draft.id, !isSaving else { return }
        isSaving = true
        errorMessage = nil

        Task {
            do {
                let craving = try await repository.createPending(from: draft)
                await NotificationService.shared.scheduleFollowUp(for: craving)
                activeDraft = nil
                isWaitingForCorrection = false
                messages.append(
                    ChatMessage(
                        role: .assistant,
                        text: "Listo. Guardé el antojo como pendiente y dentro de 4 horas te preguntaré si lo comiste."
                    )
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    func markConsumed(_ craving: Craving) {
        Task { await resolve(craving, asAvoided: false) }
    }

    func markAvoided(_ craving: Craving) {
        Task { await resolve(craving, asAvoided: true) }
    }

    private func resolve(_ craving: Craving, asAvoided: Bool) async {
        do {
            if asAvoided {
                try await repository.markAvoided(craving)
            } else {
                try await repository.markConsumed(craving)
            }
            await NotificationService.shared.cancelFollowUp(for: craving.id)
            messages.append(
                ChatMessage(
                    role: .assistant,
                    text: outcomeMessage(for: craving, asAvoided: asAvoided)
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func outcomeMessage(for craving: Craving, asAvoided: Bool) -> String {
        if asAvoided {
            return "¡Bien hecho! Confirmaste que no comiste \(craving.title). Sumamos aproximadamente \(craving.estimatedCaloriesMidpoint) kcal a tu total evitado."
        }
        return "Registrado: comiste \(craving.title). Sumamos aproximadamente \(craving.estimatedCaloriesMidpoint) kcal a tu total consumido. Seguimos sin culpas y con información útil."
    }

    private func chatMessage(for error: Error) -> String {
        if case CravingInterpreterError.creditsExhausted = error {
            return "El servicio de IA se quedó sin créditos. Ya avisamos el problema; inténtalo nuevamente más tarde."
        }
        return "No pude interpretar ese antojo ahora. Revisa tu conexión e inténtalo nuevamente."
    }
}
