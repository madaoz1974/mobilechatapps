//
//  WebSocketService.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//

// MARK: - WebSocket Service

import Foundation

class WebSocketService {
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?

    var onReceiveMessage: ((Message) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    var onUserListUpdate: (([User]) -> Void)?

    var isConnected: Bool {
        return webSocketTask != nil
    }

    deinit {
        disconnect()
    }

    func connect(url: URL, userId: String, userName: String) {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)

        // Add query parameters for user identification
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "userName", value: userName)
        ]

        if let connectionURL = urlComponents?.url {
            webSocketTask = session.webSocketTask(with: connectionURL)
            webSocketTask?.resume()
            receiveMessage()

            // Start ping timer to keep connection alive
            startPingTimer()

            onConnected?()
        }
    }

    func disconnect() {
        stopPingTimer()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        onDisconnected?()
    }

    func send(message: Message) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)

            if let jsonString = String(data: data, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                webSocketTask?.send(message) { error in
                    if let error = error {
                        print("WebSocket sending error: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleIncomingMessage(text)
                case .data(let data):
                    self?.handleIncomingData(data)
                @unknown default:
                    break
                }

                // Continue receiving messages
                self?.receiveMessage()

            case .failure(let error):
                print("Error receiving message: \(error)")
                self?.disconnect()
            }
        }
    }

    private func handleIncomingMessage(_ text: String) {
        // Handle different message types
        if let data = text.data(using: .utf8) {
            do {
                // Try to decode as a chat message
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                if text.contains("\"type\":\"userList\"") {
                    // Handle user list update
                    let userListResponse = try decoder.decode(UserListResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.onUserListUpdate?(userListResponse.users)
                    }
                } else {
                    // Handle chat message
                    let message = try decoder.decode(Message.self, from: data)
                    DispatchQueue.main.async {
                        self.onReceiveMessage?(message)
                    }
                }
            } catch {
                print("Failed to decode message: \(error)")
            }
        }
    }

    private func handleIncomingData(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let message = try decoder.decode(Message.self, from: data)

            DispatchQueue.main.async {
                self.onReceiveMessage?(message)
            }
        } catch {
            print("Failed to decode data: \(error)")
        }
    }

    // Keep connection alive with ping
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.ping()
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func ping() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("Ping failed: \(error)")
            }
        }
    }
}
