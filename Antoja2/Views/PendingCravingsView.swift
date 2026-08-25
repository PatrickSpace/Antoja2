import SwiftUI

struct PendingCravingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChatViewModel
    @State private var cravingToConfirmAsAvoided: Craving?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.pendingCravings.isEmpty {
                    ContentUnavailableView(
                        "Todo al día",
                        systemImage: "checkmark.circle",
                        description: Text("No tienes antojos pendientes de resolver.")
                    )
                    .foregroundStyle(AppTheme.ink)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.pendingCravings) { craving in
                                pendingCard(craving)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Pendientes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
        .alert(item: $cravingToConfirmAsAvoided) { craving in
            Alert(
                title: Text("Confirmar resultado"),
                message: Text("Este antojo contará en tu racha y en las calorías evitadas. ¿Confirmas que no consumiste esta comida, ni siquiera una parte?"),
                primaryButton: .default(Text("Sí, confirmo")) {
                    viewModel.markAvoided(craving)
                },
                secondaryButton: .cancel(Text("Volver"))
            )
        }
        .preferredColorScheme(.light)
    }

    private func pendingCard(_ craving: Craving) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: craving.isOverdue ? "exclamationmark.circle.fill" : "clock.fill")
                    .font(.title3)
                    .foregroundStyle(craving.isOverdue ? AppTheme.accent : AppTheme.mutedInk)

                VStack(alignment: .leading, spacing: 4) {
                    Text(craving.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("\(craving.portionText) · \(craving.calorieRangeText)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                    Text(statusText(for: craving))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(craving.isOverdue ? AppTheme.accent : AppTheme.green)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button("Lo comí") {
                    viewModel.markConsumed(craving)
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Button("No lo comí") {
                    cravingToConfirmAsAvoided = craving
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
        .padding(18)
        .antojaCard()
    }

    private func statusText(for craving: Craving) -> String {
        if craving.isOverdue {
            return "Ya puedes confirmar qué ocurrió"
        }
        return "Seguimiento \(craving.followUpDueAt.formatted(date: .omitted, time: .shortened))"
    }
}
