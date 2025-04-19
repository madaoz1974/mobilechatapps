//
//  Message.swift
//  ChatApp
//
//  Created by 車田巡 on 2025/04/18.
//
import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let senderId: String
    let content: String
    let timestamp: Date

    var isFromCurrentUser: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, senderId, content, timestamp
    }
}
