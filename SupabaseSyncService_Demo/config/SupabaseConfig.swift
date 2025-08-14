//
//  SupabaseConfig.swift
//  SupabaseSyncService_Demo
//
//  Created by Brody Whalen on 7/29/25.
//
import Foundation

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
