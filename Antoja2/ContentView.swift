import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isResolvingSession {
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    ProgressView()
                        .tint(AppTheme.accent)
                }
            } else if let user = authViewModel.user {
                MainContainerView(userID: user.uid)
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authViewModel.user?.uid)
    }
}
