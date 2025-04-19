//
//  User.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//

struct User: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    var isOnline: Bool = true

    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}
