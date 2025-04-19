//
//  MessageGroupView.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//
import SwiftUI

struct MessageGroupView: View {
    let messageGroup: [Message]
    let users: [User]

    private var isFromCurrentUser: Bool {
        return messageGroup.first?.isFromCurrentUser ?? false
    }

    private var senderName: String {
        guard let senderId = messageGroup.first?.senderId else { return "不明" }
        return users.first(where: { $0.id == senderId })?.name ?? "不明"
    }

    var body: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
            if !isFromCurrentUser {
                Text(senderName)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }

            ForEach(messageGroup) { message in
                MessageBubbleView(message: message)
            }

            if let lastMessage = messageGroup.last {
                Text(formatTimestamp(lastMessage.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
