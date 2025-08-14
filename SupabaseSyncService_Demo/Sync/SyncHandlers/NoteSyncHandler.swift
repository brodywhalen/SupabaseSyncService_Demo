//
//  NoteSyncHandler.swift
//  SupabaseSyncService_Demo
//
//  Created by Brody Whalen on 8/11/25.
//
import Foundation
import Supabase

class NoteSyncHandler: SyncActionHandler {
    
    let modelName = Note.modelName
    
    func execute(operation: SyncToOperation, using supabase: SupabaseClient) async throws {
        guard let opType = SyncOperationType(rawValue: operation.operationType) else {
            //TODO: Implement Custom error handling here
            print("Unsupported operation type")
            return
        }
        let decoder = JSONDecoder()
        let tableName = "notes"
        
        switch opType {
        case .create:
            let dto: Encodable = try decoder.decode(NoteDTO.self, from: operation.payload)
            try await supabase.from(tableName).insert(dto).execute()
        case .update:
            let dto = try decoder.decode(NoteDTO.self, from: operation.payload)
            try await supabase.from(tableName).update(dto).eq( "id", value: dto.id).execute()
        case .delete:
            guard let idString = String(data: operation.payload, encoding: .utf8) else {
                print("cannot convert id of object to be deleted to string")
                return
            }
            try await supabase.from(tableName).delete().eq("id", value: idString).execute()
        case .rpc:
            print("RPC should not be handled in in the model handlers")
            break
        }
        
    }
    
    
    
}
