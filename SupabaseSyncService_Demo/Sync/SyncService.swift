//
//  SyncService.swift
//  SupabaseSyncService_Demo
//
//  Created by Brody Whalen on 7/31/25.
//
import Foundation
import SwiftData
import Supabase


protocol Syncable: PersistentModel {
    associatedtype DTO: Codable
    static var modelName: String { get }
    var syncId: String { get }
    func toDTO() -> DTO
    // toDTO returns any codable type
}

enum SyncOperationType: String, Codable {
    case create
    case update
    case delete
    case rpc
}

protocol SyncActionHandler {
    var modelName : String { get }
    func execute(operation: SyncToOperation, using supabase: SupabaseClient) async throws
}
protocol RPCHandler {
    var rpcFunctionName: String { get }
    func execute(payload: Data, using supabase: SupabaseClient) async throws
}

actor SyncService {
    private let modelContainer: ModelContainer
    private let supabaseClient: SupabaseClient
    // Dictionary for storing actionhandlers by name
    private var modelHandlers: [String : SyncActionHandler] = [:]
    private var rpcHandlers: [String: RPCHandler] = [:]
    
    init(
        modelContainer: ModelContainer,
        supabaseClient: SupabaseClient
    ) {
        self.modelContainer = modelContainer
        self.supabaseClient = supabaseClient
    }
    
    // Registers a handler for a specific model type
    func register(modelHandler: SyncActionHandler) {
        modelHandlers[modelHandler.modelName] = modelHandler
    }
    //Registers a handler for a specific RPC call
    func register(rpcHandler: RPCHandler) {
        rpcHandlers[rpcHandler.rpcFunctionName] = rpcHandler
    }
    
    // This is the queue that is processing the sync actions in the background
    func processQueue() async {
        let context = ModelContext(modelContainer)
        
        while let operation = fetchNextOperation(context: context) {
            do {
                guard let opType = SyncOperationType(rawValue: operation.operationType) else {
                    print("Error parsing operation type: \(operation.operationType)")
                    //                    throw SyncError.unknownOperationType(operation.operationType)
                    return
                }
                
                // Route based on the operation type
                switch opType {
                case .create, .update, .delete:
                    guard let modelName = operation.modelName, let handler = modelHandlers[modelName] else {
                        //                        throw SyncError.missingHandler("CUD handler for \(operation.modelName ?? "nil")")
                        print("Error: Missing CRUD handler for \(operation.modelName ?? "nil")")
                        return
                    }
                    try await handler.execute(operation: operation, using: supabaseClient)
                    
                case .rpc:
                    guard let rpcName = operation.rpcName, let handler = rpcHandlers[rpcName] else {
                        //                        throw SyncError.missingHandler("RPC handler for \(operation.rpcName ?? "nil")")
                        print("Error: Missing RPC handler for \(operation.rpcName ?? "nil")")
                        return
                    }
                    try await handler.execute(payload: operation.payload, using: supabaseClient)
                }
                
                // On success, delete the processed operation
                context.delete(operation)
                try context.save()
                print("✅ Successfully processed op \(operation.id).")
                
            } catch {
                print("❌ Failed to sync op \(operation.id): \(error.localizedDescription).")
                print("   Halting queue to preserve order. Will retry on next sync.")
                return
            }
        }
        
        print("Sync queue processed.")
    }
    

/// Fetches the oldest operation from the queue.
private func fetchNextOperation(context: ModelContext) -> SyncToOperation? {
    var descriptor = FetchDescriptor<SyncToOperation>(sortBy: [SortDescriptor(\.created_at)])
    descriptor.fetchLimit = 1
    
    do {
        return try context.fetch(descriptor).first
    } catch {
        print("Error fetching next sync operation: \(error)")
        return nil
    }
}

}
