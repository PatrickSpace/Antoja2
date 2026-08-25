import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Circle()
                .fill(AppTheme.accentSoft.opacity(0.8))
                .frame(width: 330, height: 330)
                .blur(radius: 4)
                .offset(x: 120, y: -260)

            VStack(alignment: .leading, spacing: 28) {
                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppTheme.ink)
                        Image(systemName: "sparkles")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(AppTheme.accentSoft)
                    }
                    .frame(width: 68, height: 68)

                    Text("Antoja2")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text("Entiende el antojo, revisa los supuestos y descubre qué decisiones estás tomando.")
                        .font(.title3)
                        .foregroundStyle(AppTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: authViewModel.signInWithGoogle) {
                    HStack(spacing: 12) {
                        if authViewModel.isSigningIn {
                            ProgressView()
                                .tint(AppTheme.ink)
                        } else {
                            Text("G")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(.blue)
                        }

                        Text(authViewModel.isSigningIn ? "Conectando…" : "Continuar con Google")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 58)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(authViewModel.isSigningIn)

                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Text("Acceso privado con tu cuenta de Google.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
        }
    }
}
