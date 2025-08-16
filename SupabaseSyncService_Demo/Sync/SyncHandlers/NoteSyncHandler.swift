//
//  NoteSyncHandler.swift
//  SupabaseSyncService_Demo
//
//  Created by Brody Whalen on 8/11/25.
//
import Foundation
import Supabase

struct NotePayload: Codable {
    let id: UUID
    let title: String
    let content: String
    let created_at: Date
    let created_by: UUID
    // The 'blogs' field is simply omitted
}

struct BlogNoteRelationship: Codable{
    let note_id: UUID
    let blog_id: UUID
}


class NoteSyncHandler: SyncActionHandler {
    
    let modelName = Note.modelName
    
    func execute(operation: SyncToOperation, using supabase: SupabaseClient) async throws {
        guard let opType = SyncOperationType(rawValue: operation.operationType) else {
            //TODO: Implement Custom error handling here
            print("Unsupported operation type")
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let tableName = "notes"
        
        switch opType {
        case .create:
            let dto = try decoder.decode(NoteDTO.self, from: operation.payload)
            
            let payloadForNotesTable = NotePayload(
                id: dto.id,
                title: dto.title,
                content: dto.content,
                created_at: dto.created_at,
                created_by: dto.created_by
            )
            // Inserting the Note with no relations
            try await supabase.from(tableName).insert(payloadForNotesTable).execute()
            //
            if !dto.blogs.isEmpty {
                let relations = dto.blogs.map { blogId in
                    BlogNoteRelationship(note_id: dto.id, blog_id: blogId)
                }
                
                // Upsert will add new links and silently ignore existing ones.
                try await supabase.from("blog_notes").upsert(relations).execute()
            }


                
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
