import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var notificationMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Cuenta") {
                    LabeledContent("Nombre", value: authViewModel.displayName)
                    if let email = authViewModel.user?.email {
                        LabeledContent("Google", value: email)
                    }
                }

                Section("Seguimiento") {
                    LabeledContent("Pregunta de resultado", value: "Después de 4 horas")

                    Button("Activar notificaciones") {
                        Task {
                            let enabled = await NotificationService.shared.requestAuthorizationIfNeeded()
                            notificationMessage = enabled
                                ? "Las notificaciones están activas."
                                : "Puedes activarlas desde Ajustes de iOS."
                        }
                    }

                    if let notificationMessage {
                        Text(notificationMessage)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                }

                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        authViewModel.signOut()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
}
