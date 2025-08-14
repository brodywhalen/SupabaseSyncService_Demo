//
//  Item.swift
//  SupabaseSyncService_Demo
//
//  Created by Brody Whalen on 7/28/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

@Model
class Note: Syncable {
    
    // Syncable Conformance
    static let modelName: String = "notes"
    var syncId: String { self.id.uuidString}
    
    func toDTO() -> NoteDTO {
        NoteDTO(
            id: self.id,
            title: self.title,
            content: self.content,
            created_at: self.created_at,
            created_by: self.created_by.id,
            blogs: self.blogs?.map { $0.id } ?? []
            )
    }
    
    // Model
    
    var id: UUID
    var title: String
    var content: String
    var created_at: Date
    var created_by: User
    var blogs: [Blog]?
    
    init( id: UUID = UUID(), title: String, content: String, created_by: User, created_at: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.created_by = created_by
        self.created_at = created_at
    }
}
@Model
class Blog {
    // Syncable Conformance
    static let modelName: String = "notes"
    var syncId: String { self.id.uuidString}
    func toDTO() -> BlogDTO {
        BlogDTO(
            id: self.id,
            title: self.title,
            created_at: self.created_at,
            created_by: self.created_by.id,
            notes: self.notes?.map { $0.id } ?? []
            )
    }
    // Model
    var id: UUID
    var title: String
    var created_by: User
    var created_at: Date
    
    @Relationship(inverse: \Note.blogs)
    var notes: [Note]?
    
    init(id: UUID = UUID(), notes: [Note], title: String, created_by: User, created_at: Date = Date()) {
        self.id = id
        self.notes = notes
        self.title = title
        self.created_by = created_by
        self.created_at = created_at
    }
}


@Model
class User {
    // Syncable Conformance
    static let modelName: String = "users"
    var syncId: String { self.id.uuidString}
    
    func toDTO() -> UserDTO {
        UserDTO(
            id: self.id,
            email: self.email,
            username: self.username,
            created_at: self.created_at,
            blogs: self.blogs?.map { $0.id } ?? [],
            notes: self.notes?.map { $0.id } ?? []
            )
    }
    // Model
    var id: UUID
    @Attribute(.unique) var username: String
    @Attribute(.unique) var email: String
    var created_at: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Blog.created_by)
    var blogs: [Blog]?
    @Relationship(deleteRule: .cascade, inverse: \Note.created_by)
    var notes: [Note]?
    
    
    init(id: UUID, username: String, email: String, created_at: Date = Date()) {
        self.id = id
        self.username = username
        self.email = email
        self.created_at = created_at
    }
}

@Model
final class SyncToOperation {
    // add index to create queue quickly
    #Index<SyncToOperation>([\.created_at])
    
    var id: UUID
    var modelName: String?
    var rpcName: String?
    var operationType: String
    var payload: Data
    var created_at: Date

    init(modelName: String, operationType: String, payload: Data) {
        self.id = UUID()
        self.modelName = modelName
        self.operationType = operationType
        self.payload = payload
        self.created_at = Date.now
    }
    // init for RPC operations
    
    init (rpcName: String, payload: Data) {
        self.id = UUID()
        self.rpcName = rpcName
        self.payload = payload
        self.created_at = Date.now
        self.modelName = nil
        self.operationType = "rpc"
    }
}
