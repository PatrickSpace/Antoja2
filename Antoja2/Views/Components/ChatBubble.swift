import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    let isActiveDraft: Bool
    let isSaving: Bool
    let onChange: (CravingDraft) -> Void
    let onRegister: (CravingDraft) -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.role == .user { Spacer(minLength: 54) }

            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.accentSoft)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(message.role == .user ? Color.white : AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let draft = message.draft {
                    CravingDraftCard(
                        draft: draft,
                        isActive: isActiveDraft,
                        isSaving: isSaving,
                        onChange: { onChange(draft) },
                        onRegister: { onRegister(draft) }
                    )
                }
            }
            .padding(message.draft == nil ? 14 : 16)
            .background(message.role == .user ? AppTheme.ink : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                if message.role == .assistant {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                }
            }

            if message.role == .assistant { Spacer(minLength: 28) }
        }
    }
}
