// This file notices when a network connection is found or updated and then attempts to sync the queue in the background. It checks every 30s.
//
//

import Foundation
import Network // Required for network monitoring

enum SyncStatus: Equatable {
    case idle
    case syncing
    case success
    case error(Error)
    
    static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.success, .success):
            return true
        case (.error, .error): // For simplicity, we can say any two errors are equal
            return true
        default:
            return false
        }
    }
}

@MainActor
class SyncManager: ObservableObject {
    private var syncService: SyncService? = nil
    private let networkMonitor = NWPathMonitor()
    private var isNetworkAvailable = false
    private var syncTask: Task<Void, Error>?
    @Published var syncStatus: SyncStatus = .idle
    let periodicSyncInterval: TimeInterval = 30 // 30 seconds
    
    init(/*syncService: SyncService*/) {
//        self.syncService = syncService
        
        // Start monitoring network status changes
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.handlePathUpdate(path)
            }
        }
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        self.isNetworkAvailable = path.status == .satisfied
        print("Network status changed. Available: \(self.isNetworkAvailable)")
        // When the network becomes available, trigger an immediate sync
        if self.isNetworkAvailable {
            self.triggerSync()
        }
    }
    func attatchSyncService(_ syncService: SyncService) {
        self.syncService = syncService
    }
    
    /// Starts the sync manager. This should be called once when the app launches.
    func start() {
        // You can specify .main here, but the Task ensures safety regardless.
        networkMonitor.start(queue: .main)
        
        // Cancel any existing task to avoid duplicates
        syncTask?.cancel()
        
        // Start a new long-running task for periodic syncing
        syncTask = Task {
            while !Task.isCancelled {
                // Wait for the defined interval
                try await Task.sleep(for: .seconds(periodicSyncInterval))
                //check to see if sync service is intialized
                guard let syncService = self.syncService else {
                    print("❌ Skipping periodic sync, service not initialized.")
                    continue // Skip this loop iteration
                }
                // If the network is available, process the queue
                if isNetworkAvailable {
                    print("Periodic sync triggered...")
                    await syncService.processQueue()
                } else {
                    print("Skipping periodic sync, network is unavailable.")
                }
            }
        }
    }
    
    /// Triggers an immediate, one-off sync if the network is available.
    /// Call this after a user performs an action for faster feedback.
    func triggerSync() {
        guard isNetworkAvailable else {
            print("Sync trigger skipped, network is unavailable.")
            return
        }
        
        // Don't start a new sync if one is already in progress
        guard self.syncStatus != .syncing else {
            print("Sync already in progress. Skipping trigger.")
            return
        }
        
        Task {
            print("Manual sync triggered...")
            self.syncStatus = .syncing // Update state
            do {
                //TODO: Make sure errors are progated through the Sync service (current caught inside)
                guard let syncService = self.syncService else {
                    let error = NSError(
                        domain: "com.YourApp.SyncManager", // A string to identify the error source
                        code: 1001,                         // A unique code for this specific error
                        userInfo: [
                            NSLocalizedDescriptionKey: "Sync service has not been initialized."
                        ]
                    )
                    throw error
                }
                try await syncService.processQueue()
                self.syncStatus = .success // Update state
            } catch {
                self.syncStatus = .error(error) // Update state
            }
        }
    }
}

