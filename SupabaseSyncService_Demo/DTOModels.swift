//
//  DTOModels.swift
//  SupabaseSyncService_Demo
//
// This are the transfer models to be stored in the SyncToOperation Persistent Model.

import Foundation

struct NoteDTO: Codable {
    let id: UUID
    let title: String
    let content: String
    let created_at: Date
    let created_by: UUID
    let blogs: [UUID]
    
}

struct BlogDTO: Codable {
    let id: UUID
    let title: String
    let created_at: Date
    let created_by: UUID
    let notes: [UUID]
}

struct UserDTO: Codable {
    let id: UUID
    let email: String
    let username: String
    let created_at: Date
    let blogs: [UUID]
    let notes: [UUID]
}

