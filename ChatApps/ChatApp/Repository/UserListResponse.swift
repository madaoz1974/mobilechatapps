//
//  UserListResponse.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//

// For decoding user list updates
struct UserListResponse: Codable {
    let type: String
    let users: [User]
}
