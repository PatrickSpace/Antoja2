import Combine
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isResolvingSession = true
    @Published private(set) var isSigningIn = false
    @Published var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    var displayName: String {
        user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? user?.email?.components(separatedBy: "@").first
            ?? "usuario"
    }

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isResolvingSession = false
            }
        }
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    func signInWithGoogle() {
        guard !isSigningIn else { return }
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "No se encontró la configuración de Google."
            return
        }
        guard let presentingViewController = UIApplication.shared.antojaRootViewController else {
            errorMessage = "No se pudo abrir el inicio de sesión."
            return
        }

        isSigningIn = true
        errorMessage = nil
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let error {
                    self.isSigningIn = false
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard
                    let googleUser = result?.user,
                    let idToken = googleUser.idToken?.tokenString
                else {
                    self.isSigningIn = false
                    self.errorMessage = "Google no devolvió una credencial válida."
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: googleUser.accessToken.tokenString
                )

                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    self.user = result.user
                    self.isSigningIn = false
                    await self.saveProfile(for: result.user)
                } catch {
                    self.isSigningIn = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signOut() {
        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
            user = nil
            Task {
                await NotificationService.shared.cancelDailyPendingReminders()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveProfile(for user: User) async {
        var data: [String: Any] = [
            "displayName": user.displayName ?? "",
            "email": user.email ?? "",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let photoURL = user.photoURL?.absoluteString {
            data["photoURL"] = photoURL
        }

        try? await Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .setData(data, merge: true)
    }
}

private extension UIApplication {
    var antojaRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMostViewController
    }
}

private extension UIViewController {
    var topMostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostViewController
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController ?? tabBarController
        }
        return self
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
