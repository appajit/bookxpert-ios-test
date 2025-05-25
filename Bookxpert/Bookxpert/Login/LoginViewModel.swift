import Foundation
import Combine

protocol LoginViewModelDelegate: AnyObject {
    func didLoginSuccessfully()
}


final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoggingIn: Bool = false
    
    private let authService: AuthenticationServicing
    weak var delegate: LoginViewModelDelegate?
    private let googleCredentailProvider: GoogleCredentailProviding
    private let userDetailsRepository: UserDetailsRepositoryProtcol

    init(
        authService: AuthenticationServicing,
        googleCredentailProvider: GoogleCredentailProviding,
        userDetailsRepository: UserDetailsRepositoryProtcol,
        delegate: LoginViewModelDelegate?
    ) {
        self.authService = authService
        self.delegate = delegate
        self.googleCredentailProvider = googleCredentailProvider
        self.userDetailsRepository = userDetailsRepository
    }
    
    func googleSignIn() {
        isLoggingIn = true

        Task {
            do {
                let authCredential = try await googleCredentailProvider.getCredentials()
                let user = try await authService.login(credential: authCredential)

                await MainActor.run {
                    let userDetails = UserDetails(email: user.email, displayName: user.displayName, uid: user.uid, profileImage: nil)
                    userDetailsRepository.saveUserDetails(userDetails)
                    isLoggingIn = false
                    delegate?.didLoginSuccessfully()
                }
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
