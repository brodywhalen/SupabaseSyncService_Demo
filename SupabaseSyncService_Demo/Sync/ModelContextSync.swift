//
//  ModelContextSync.swift
//  SupabaseSyncService_Demo
//
//  Created by Brody Whalen on 8/6/25.
//

import Foundation
import SwiftData


extension ModelContext {
    
    func queueSyncOperation<T: Syncable>(for model: T, type: SyncOperationType){
        
        guard type == .create || type == .update || type == .delete else {
            print("Error: use queueCustomerRPCOperation for RPC calls")
            return
        }
        do {
            let payload: Data
            if type == .delete {
                // do deletes only need the id for payload
                payload = Data(model.syncId.utf8)
            } else {
                // fore create or update the payload is the entire DTO
                let dto = model.toDTO()
                let encoder = JSONEncoder()
                // encode based on supabase recommendation
                encoder.dateEncodingStrategy = .iso8601
                payload = try encoder.encode(dto)
            }
            
            let syncOp = SyncToOperation(
                modelName: T.modelName,
                operationType: type.rawValue,
                payload: payload
            )
            self.insert(syncOp)
            print("Queued sync op: \(type.rawValue) for \(T.modelName) \(model.syncId)")
        } catch {
            print("Failed to queue sync operation: \(error)")
        }
        
    }
    // TODO: Figure out how to implement RPC calls. May need to just have custom endpoint.
    func queueCustomRPCOperation(rpcOperation: String, payload: Encodable) {
         do {
             let payloadData = try JSONEncoder().encode(payload)
             let syncOp = SyncToOperation(
                 rpcName: rpcOperation,
                 payload: payloadData
             )
             self.insert(syncOp)
             print("Queued custom RPC for \(rpcOperation).")
         } catch {
             print("Failed to queue RPC operation: \(error)")
         }
     }
}
