
import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

protocol GoogleCredentailProviding {
    func getCredentials() async throws -> AuthCredential
}

enum GoogleSignInError: Error {
    case missingClientId
    case signInFailed
}
final class GoogleCredentailProvider: GoogleCredentailProviding {
    
    private let presentingViewController: UIViewController
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }

    
    @MainActor
    func getCredentials() async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw GoogleSignInError.missingClientId
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard
                    let user = result?.user,
                    let idToken = user.idToken?.tokenString
                else {
                    continuation.resume(throwing: GoogleSignInError.signInFailed)
                    return
                }

                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                continuation.resume(with: .success((credential)))
            }
        }
    }
}
