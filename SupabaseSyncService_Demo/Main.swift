//
//  SupabaseSyncService_DemoApp.swift
//  SupabaseSyncService_Demo
//
//  Created by Brody Whalen on 7/28/25.
//

import SwiftUI
import SwiftData

@main
struct SupabaseSyncService_DemoApp: App {
    @StateObject private var authService: AuthService = AuthService.shared!
//    private var syncService: SyncService
    @StateObject private var syncManager: SyncManager = SyncManager()
    var sharedModelContainer: ModelContainer
    // let syncManager; syncManager // handles startup logic and st
    
    init() {
        //Setup model container
        sharedModelContainer = {
            let schema = Schema([
                User.self,
                Blog.self,
                Note.self,
                SyncToOperation.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
        AuthService.configure(modelContainer: sharedModelContainer)
        
    }
    
    var body: some Scene {
        WindowGroup {
                    ContentView()
                        .environmentObject(authService)
                        .environmentObject(syncManager)
                        .task {
                            guard let auth = AuthService.shared else {
                                print(">>> Auth not ready yet")
                                return
                            }
                            let syncService = SyncService(modelContainer: sharedModelContainer, supabaseClient: auth.supabase)
                            let noteSyncHandler = NoteSyncHandler()
                            await syncService.register(modelHandler: noteSyncHandler)
                            syncManager.attatchSyncService(syncService)
                            syncManager.start()
                            
                        }
        }
        .modelContainer(sharedModelContainer)
        
        
    }

}
