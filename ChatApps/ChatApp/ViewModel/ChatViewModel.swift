//
//  ChatViewModel.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//
import SwiftUI

// MARK: - ViewModel with @Observable
@Observable class ChatViewModel {
    // State
    var messages: [Message] = []
    var newMessageText: String = ""
    var isConnected: Bool = false
    var users: [User] = []
    var currentUser: User
    var errorMessage: String?

    private let webSocketService = WebSocketService()
    private let serverURL: URL

    init(userId: String = UUID().uuidString, userName: String = "ユーザー\(Int.random(in: 1000...9999))") {
        // Set server URL - replace with your actual WebSocket server URL
        serverURL = URL(string: "wss://your-chat-server.com/chat")!

        // Initialize current user
        currentUser = User(id: userId, name: userName)

        // Setup WebSocket handlers
        setupWebSocketHandlers()
    }

    private func setupWebSocketHandlers() {
        webSocketService.onReceiveMessage = { [weak self] message in
            guard let self = self else { return }

            // Must be on main thread to update @Observable properties
            DispatchQueue.main.async {
                var newMessage = message
                newMessage.isFromCurrentUser = message.senderId == self.currentUser.id
                self.messages.append(newMessage)
            }
        }

        webSocketService.onConnected = { [weak self] in
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.errorMessage = nil
            }
        }

        webSocketService.onDisconnected = { [weak self] in
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.errorMessage = "接続が切断されました。再接続してください。"
            }
        }

        webSocketService.onUserListUpdate = { [weak self] users in
            DispatchQueue.main.async {
                self?.users = users
            }
        }
    }

    func connect() {
        webSocketService.connect(url: serverURL, userId: currentUser.id, userName: currentUser.name)
    }

    func disconnect() {
        webSocketService.disconnect()
    }

    func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let message = Message(
            id: UUID().uuidString,
            senderId: currentUser.id,
            content: newMessageText,
            timestamp: Date(),
            isFromCurrentUser: true
        )

        webSocketService.send(message: message)

        // Optimistically add to local messages
        messages.append(message)
        newMessageText = ""
    }

    // Delete a message (only local)
    func deleteMessage(at indexSet: IndexSet) {
        messages.remove(atOffsets: indexSet)
    }

    // Message grouping for better UI display
    func messageGroups() -> [[Message]] {
        var groups: [[Message]] = []
        var currentGroup: [Message] = []
        var currentSenderId: String?

        for message in messages {
            if let id = currentSenderId, id == message.senderId {
                // Same sender, add to current group
                currentGroup.append(message)
            } else {
                // New sender, start a new group
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                }
                currentGroup = [message]
                currentSenderId = message.senderId
            }
        }

        // Add the last group
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups
    }
}
