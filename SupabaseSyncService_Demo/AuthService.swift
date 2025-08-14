//
//  Supabase.swift
//  SupabaseSyncService_Demo
//
//  Created by Brody Whalen on 7/29/25.
//
import Foundation
import Supabase
import GoogleSignIn
import SwiftUI


// This will be a singleton instance for the Auth service

@MainActor

class AuthService: ObservableObject {
    // creates single instance of the auth service to be passed down through environment
    static let shared = AuthService()
    
    @Published private(set) var session: Session?
    
    let supabase = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.key
    )
    
    // Session listener
    private init() {
        Task{
            for await state in supabase.auth.authStateChanges {
                self.session = state.session
                
                
                
                
                
                
            }
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
    }
    
    func googleSignIn() async throws {
        guard let rootViewController = getRootViewController() else {
            print("Could not find a root view controller.")
            return
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            print("No idToken found.")
            return
        }
        let accessToken = result.user.accessToken.tokenString
        try await supabase.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    
    
    
}

