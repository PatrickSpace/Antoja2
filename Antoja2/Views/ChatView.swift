import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var viewModel: ChatViewModel

    @FocusState private var isComposerFocused: Bool
    @State private var showsPending = false
    @State private var showsSettings = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                conversation
                pendingHandle
                composer
            }
        }
        .sheet(isPresented: $showsPending) {
            PendingCravingsView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
        .alert("No pudimos completar la acción", isPresented: errorBinding) {
            Button("Entendido", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Inténtalo nuevamente.")
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Menu {
                Button {
                    showsPending = false
                    showsSettings = false
                } label: {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

                Button {
                    showsSettings = true
                } label: {
                    Label("Configuración", systemImage: "gearshape")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Antoja2")
                    .font(.headline.weight(.black))
                    .foregroundStyle(AppTheme.ink)
                Text("Hola, \(authViewModel.displayName)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            if !viewModel.pendingCravings.isEmpty {
                Button {
                    showsPending = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text("\(viewModel.pendingCravings.count)")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(AppTheme.accentSoft.opacity(0.7))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(
                            message: message,
                            isActiveDraft: message.draft?.id == viewModel.activeDraft?.id,
                            isSaving: viewModel.isSaving,
                            onChange: { draft in
                                viewModel.askToChange(draft)
                                isComposerFocused = true
                            },
                            onRegister: viewModel.register
                        )
                        .id(message.id)
                    }

                    if viewModel.isProcessing {
                        HStack(spacing: 8) {
                            ProgressView().tint(AppTheme.accent)
                            Text("Entendiendo tu antojo…")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.mutedInk)
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) {
                guard let lastMessage = viewModel.messages.last else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    private var pendingHandle: some View {
        Button {
            showsPending = true
        } label: {
            VStack(spacing: 6) {
                Capsule()
                    .fill(AppTheme.mutedInk.opacity(0.32))
                    .frame(width: 38, height: 4)

                HStack(spacing: 8) {
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.bold))
                    Text(pendingHandleText)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(AppTheme.mutedInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height < -28 {
                        showsPending = true
                    }
                }
        )
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                text: $viewModel.inputText,
                prompt: Text(composerPlaceholder)
                    .foregroundStyle(AppTheme.mutedInk),
                axis: .vertical
            ) {
                Text(composerPlaceholder)
            }
                .font(.body)
                .foregroundStyle(AppTheme.ink)
                .tint(AppTheme.accent)
                .lineLimit(2...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .focused($isComposerFocused)
                .submitLabel(.send)
                .onSubmit(viewModel.sendCurrentMessage)

            Button(action: viewModel.sendCurrentMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(canSend ? AppTheme.accent : AppTheme.mutedInk.opacity(0.25))
                    .clipShape(Circle())
            }
            .disabled(!canSend)
        }
        .padding(10)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.07), radius: 18, y: 8)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private var pendingHandleText: String {
        if viewModel.pendingCravings.isEmpty {
            return "Desliza para ver pendientes"
        }
        return "\(viewModel.pendingCravings.count) antojo\(viewModel.pendingCravings.count == 1 ? "" : "s") pendiente\(viewModel.pendingCravings.count == 1 ? "" : "s")"
    }

    private var composerPlaceholder: String {
        viewModel.isWaitingForCorrection
            ? "Escribe qué debo cambiar…"
            : "¿Qué se te antoja?"
    }

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isProcessing
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
