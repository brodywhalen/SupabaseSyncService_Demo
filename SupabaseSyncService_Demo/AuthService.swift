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
import SwiftData


// This will be a singleton instance for the Auth service

@MainActor

class AuthService: ObservableObject {
    // creates single instance of the auth service to be passed down through environment
    static var shared : AuthService?
    private let modelContainer:ModelContainer
    static func configure(modelContainer: ModelContainer) {
        AuthService.shared = AuthService(modelContainer: modelContainer)
    }
    
    @Published private(set) var session: Session?
    
    let supabase = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.key
    )
    
    // Session listener
    private init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        Task{
            for await state in supabase.auth.authStateChanges {
                self.session = state.session
                
                if let session = state.session  {
                    self.syncUserProfile(session:session)
                }
                
                
                
                
            }
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
    }
    
    func googleSignIn(modelContext: ModelContext) async throws {
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
        
        // after signin update user data
        

        
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    private func syncUserProfile(session: Session) {
        // Create a dedicated context for this background-safe task
        let context = ModelContext(self.modelContainer)
        
        let userId = session.user.id
        let predicate = #Predicate<User> { $0.id == userId }
        var fetchDescriptor = FetchDescriptor(predicate: predicate)
        fetchDescriptor.fetchLimit = 1

        do {
            let existingUsers = try context.fetch(fetchDescriptor)
            if existingUsers.isEmpty {
                let userEmail = session.user.email ?? ""
                let userUsername = session.user.userMetadata["name"]?.stringValue ?? "User"
                
                let newUser = User(id: userId, username: userUsername, email: userEmail)
                context.insert(newUser)
                try context.save()
                print("✅ New local user created for \(userUsername)")
            } else {
                print("✅ Returning user found in local store.")
            }
        } catch {
            print("❌ Error syncing user profile: \(error)")
        }
    }
    
    
    
    
}

