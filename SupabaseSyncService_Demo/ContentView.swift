//
//  ContentView.swift
//  SupabaseSyncService_Demo
//
//  Created by Brody Whalen on 7/28/25.
//

import SwiftUI
import SwiftData
import GoogleSignIn
import Supabase

// SECTION SUPABASE CONFIG
let supabase = SupabaseClient(
  supabaseURL: SupabaseConfig.url,
  supabaseKey: SupabaseConfig.key
)
enum SupabaseConfig {
    static var url: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String else {
            fatalError("SupabaseURL not found in Info.plist. Please add it.")
        }
        print("DEBUG: Trying to create URL from this string: '\(urlString)'")
        guard let url = URL(string: urlString) else {
            fatalError("Invalid SupabaseURL in Info.plist.")
        }
        return url
    }()

    static var key: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseKey") as? String else {
            fatalError("SupabaseKey not found in Info.plist. Please add it.")
        }
        return key
    }()
}

class UserStateData: ObservableObject {
    @Published var session: Session?
    
    init() {
        Task{
            for await state in supabase.auth.authStateChanges {
                self.session = state.session
            }
        }
    }
}

// SECTION: CONTENT --------------------------
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @StateObject var userData = UserStateData()
    
    var body: some View {
        VStack {
            
            Text("Hello World!")
            Button("Sign In") {
                Task {
                    do {
                        try await self.googleSignIn()
                    } catch {
                        print("Error signing in: \(error)")
                    }
                }
            }
            Text("Login State:\(userData.session == nil ? "Logged Out" : "Logged In") ")
            Text("User ID: \(userData.session?.user.id.uuidString ?? "N/A")")
        }
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
    
    private func getRootViewController() -> UIViewController? {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
    }
    
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
