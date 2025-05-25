//
//  AuthenticationService.swift
//  Bookxpert
//
//  Created by Appaji Tholeti on 22/05/2025.
//

import Foundation
import FirebaseAuth

protocol AuthenticationServicing {
    func login(credential: AuthCredential) async throws -> User
}

protocol FirebaseAuthProviding {
    func signIn(credential: AuthCredential) async throws -> AuthDataResult
}

extension Auth: FirebaseAuthProviding {
    func signIn(credential: AuthCredential) async throws -> AuthDataResult {
        return try await self.signIn(with: credential)
    }
}

final class AuthenticationService: AuthenticationServicing {
    private let authProvider: FirebaseAuthProviding

    init(authProvider: FirebaseAuthProviding = Auth.auth()) {
        self.authProvider = authProvider
    }

    func login(credential: AuthCredential) async throws -> User {
        let authDataResult = try await authProvider.signIn(credential: credential)
        return authDataResult.user
    }
}
