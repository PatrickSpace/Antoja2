import SwiftUI

struct CravingDraftCard: View {
    let draft: CravingDraft
    let isActive: Bool
    let isSaving: Bool
    let onChange: () -> Void
    let onRegister: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Text(draft.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)

                HStack(spacing: 8) {
                    Label(draft.portionText, systemImage: "takeoutbag.and.cup.and.straw")
                    Text("·")
                    Text(draft.calorieRangeText)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.mutedInk)
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Supuestos usados", systemImage: "checklist")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)

                ForEach(draft.assumptions) { assumption in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(assumption.label)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(assumption.value)
                                .font(.subheadline)
                                .multilineTextAlignment(.trailing)
                        }
                        Text(assumption.reason)
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                }
            }
            .padding(14)
            .background(AppTheme.background.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if isActive {
                HStack(spacing: 10) {
                    Button("Cambiar", action: onChange)
                        .buttonStyle(SecondaryActionButtonStyle())

                    Button(action: onRegister) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Registrar")
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(isSaving)
                }
            } else {
                Label("Este resumen ya fue actualizado o registrado", systemImage: "checkmark.circle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(Color.white.opacity(configuration.isPressed ? 0.6 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
    }
}
