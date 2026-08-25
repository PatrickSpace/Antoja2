import FirebaseCore
import GoogleSignIn
import SwiftUI

@main
struct Antoja2App: App {
    @StateObject private var authViewModel: AuthViewModel

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        _authViewModel = StateObject(wrappedValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
