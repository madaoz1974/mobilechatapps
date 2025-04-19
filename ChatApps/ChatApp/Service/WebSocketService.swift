//
//  WebSocketService.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//

// MARK: - WebSocket Service

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
        // セッション設定を調整して接続の安定性を向上
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.timeoutIntervalForResource = 60

        let session = URLSession(configuration: sessionConfig)

        // URLが有効な形式かを確認
        guard url.scheme == "ws" || url.scheme == "wss" else {
            print("エラー: 無効なURL形式 - WebSocketにはws://またはwss://プロトコルが必要です: \(url)")
            onDisconnected?()
            return
        }

        print("WebSocket接続を試行: \(url)")

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        // 接続成功したと仮定して（実際のハンドシェイクの成功は受信イベントで確認）
        receiveMessage()

        // ping/pongの開始
        startPingTimer()

        // 接続通知（注：実際には最初のメッセージ受信時に接続成功とみなすべき）
        onConnected?()
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
                print("送信メッセージ: \(jsonString)")
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                webSocketTask?.send(message) { error in
                    if let error = error {
                        print("WebSocket送信エラー: \(error)")
                    }
                }
            }
        } catch {
            print("メッセージのエンコードに失敗: \(error)")
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                print("WebSocketメッセージ受信成功")

                switch message {
                case .string(let text):
                    print("受信テキスト: \(text)")
                    self?.handleIncomingMessage(text)
                case .data(let data):
                    print("受信データ (\(data.count) bytes)")
                    self?.handleIncomingData(data)
                @unknown default:
                    print("不明なメッセージタイプ")
                }

                // 引き続きメッセージを受信
                self?.receiveMessage()

            case .failure(let error):
                print("メッセージ受信エラー: \(error)")

                // 特定のエラーの詳細情報を出力
                if let urlError = error as? URLError {
                    print("URLエラーコード: \(urlError.code.rawValue)")
                    print("エラー説明: \(urlError.localizedDescription)")

                    if let failingURLString = urlError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String {
                        print("失敗したURL: \(failingURLString)")
                    }
                }

                // 接続を終了し、再接続のトリガーを作成
                self?.disconnect()
            }
        }
    }

    private func handleIncomingMessage(_ text: String) {
        // 異なるメッセージタイプを処理
        if let data = text.data(using: .utf8) {
            do {
                // チャットメッセージとしてデコード
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                if text.contains("\"type\":\"userList\"") {
                    // ユーザーリスト更新を処理
                    let userListResponse = try decoder.decode(UserListResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.onUserListUpdate?(userListResponse.users)
                    }
                } else {
                    // チャットメッセージを処理
                    let message = try decoder.decode(Message.self, from: data)
                    DispatchQueue.main.async {
                        self.onReceiveMessage?(message)
                    }
                }
            } catch {
                print("メッセージのデコードに失敗: \(error)")
                print("受信したJSON: \(text)")
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
            print("データのデコードに失敗: \(error)")
            print("受信データ: \(data.base64EncodedString())")
        }
    }

    // ping/pongによる接続維持
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
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
                print("Ping失敗: \(error)")
            }
        }
    }
}
