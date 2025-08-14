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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var syncManager: SyncManager
    @Query(sort: \SyncToOperation.created_at, order: .forward) private var syncOperations: [SyncToOperation]
    var body: some View {
        VStack {
            
            Text("Hello World!")
            Button("Sign In") {
                Task {
                    do {
                        try await authService.googleSignIn(modelContext: modelContext)
                        

                    } catch {
                        print("Error signing in: \(error)")
                    }
                }
            }
            Button("Log out") {
                Task {
                    do {
                        try await authService.signOut()
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            }
            Text("Login State:\(authService.session == nil ? "Logged Out" : "Logged In") ")
            Text("User ID: \(authService.session?.user.id.uuidString ?? "N/A")")
            Button("Create Note") {
                addNote(title: "Test Note", content: "This is a test note \(Int.random(in: 0...1000))")
            }
            Divider()
            Text("Sync State: \(syncManager.syncStatus)")
            List {
                ForEach(syncOperations) { operation in
                    Text("\(operation.created_at) \(operation.operationType)")
                }
            }
            Button("Trigger Sync!") {
                syncManager.triggerSync()
            }
        }
    }
    func addNote (title: String, content: String) {
        guard let currentUserId = authService.session?.user.id else {
            print("could not get current user id... is the user logged in?")
            return
        }
        
        do {
            // 2. Create a predicate to find the local User with that ID
            let predicate = #Predicate<User> { user in
                user.id == currentUserId
            }
            
            // Use a FetchDescriptor for a specific, one-time fetch
            var fetchDescriptor = FetchDescriptor(predicate: predicate)
            fetchDescriptor.fetchLimit = 1 // We only need one user

            // 3. Fetch the User from SwiftData
            if let currentUser = try modelContext.fetch(fetchDescriptor).first {
                // 4. Create and insert the new Note
                let newNote = Note(title: title, content: content, created_by: currentUser)
                modelContext.insert(newNote)
                modelContext.queueSyncOperation(for: newNote, type: .create)
                print("✅ Note created successfully for user: \(currentUser.username)")
            } else {
                print("Error: Could not find a local User with ID: \(currentUserId)")
            }
        } catch {
            print("Error fetching user: \(error)")
        }
        
    }
}

