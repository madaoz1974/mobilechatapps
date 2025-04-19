// server.js - WebSocketチャットサーバーの実装
const WebSocket = require('ws');
const http = require('http');
const url = require('url');
const { v4: uuidv4 } = require('uuid');

// HTTPサーバーの作成
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('WebSocket Chat Server');
});

// WebSocketサーバーの作成
const wss = new WebSocket.Server({ server });

// ユーザー管理
const users = new Map(); // userId -> user情報を格納

// メッセージの配信履歴（オプション - 接続時に過去メッセージを配信する場合）
const messageHistory = [];
const MAX_HISTORY = 50; // 保持する最大メッセージ数

// 全クライアントにメッセージを送信する関数
function broadcast(data, excludeUserId = null) {
  const message = typeof data === 'string' ? data : JSON.stringify(data);
  
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN && client.userId !== excludeUserId) {
      client.send(message);
    }
  });
}

// ユーザーリストの更新をブロードキャスト
function broadcastUserList() {
  const userList = Array.from(users.values()).map(user => ({
    id: user.id,
    name: user.name,
    isOnline: user.isOnline
  }));
  
  const userListMessage = {
    type: 'userList',
    users: userList
  };
  
  broadcast(userListMessage);
}

// 接続イベントの処理
wss.on('connection', (ws, req) => {
  // URLからユーザー情報を取得
  const parameters = url.parse(req.url, true).query;
  const userId = parameters.userId || uuidv4();
  const userName = parameters.userName || `ゲスト${Math.floor(Math.random() * 1000)}`;
  
  // クライアントにユーザーIDを紐付ける
  ws.userId = userId;
  
  // ユーザー情報を保存
  const user = {
    id: userId,
    name: userName,
    isOnline: true,
    ws: ws
  };
  
  users.set(userId, user);
  console.log(`ユーザー接続: ${userName} (${userId})`);
  
  // 接続確認メッセージを送信
  ws.send(JSON.stringify({
    id: uuidv4(),
    senderId: 'system',
    content: `${userName}さん、チャットに接続しました。`,
    timestamp: new Date().toISOString()
  }));
  
  // 過去のメッセージ履歴を送信（オプション）
  if (messageHistory.length > 0) {
    messageHistory.forEach(msg => {
      ws.send(JSON.stringify(msg));
    });
  }
  
  // ユーザーリストを更新して全クライアントに送信
  broadcastUserList();
  
  // メッセージの受信処理
  ws.on('message', (data) => {
    try {
      // データをJSONとしてパース
      const message = JSON.parse(data);
      
      // 必要なフィールドが揃っているか確認
      if (message.id && message.senderId && message.content) {
        // タイムスタンプがない場合は追加
        if (!message.timestamp) {
          message.timestamp = new Date().toISOString();
        }
        
        // メッセージを履歴に追加
        messageHistory.push(message);
        if (messageHistory.length > MAX_HISTORY) {
          messageHistory.shift(); // 最も古いメッセージを削除
        }
        
        // 送信者の名前を追加
        const sender = users.get(message.senderId);
        const enhancedMessage = {
          ...message,
          senderName: sender ? sender.name : '不明'
        };
        
        // 全クライアントにメッセージをブロードキャスト
        broadcast(enhancedMessage);
        
        console.log(`メッセージ受信: ${sender ? sender.name : '不明'}: ${message.content}`);
      }
    } catch (error) {
      console.error('メッセージの処理中にエラーが発生しました:', error);
      // エラーメッセージをクライアントに送信
      ws.send(JSON.stringify({
        id: uuidv4(),
        senderId: 'system',
        content: 'エラー: メッセージを処理できませんでした。',
        timestamp: new Date().toISOString()
      }));
    }
  });
  
  // 切断イベントの処理
  ws.on('close', () => {
    if (users.has(userId)) {
      const userName = users.get(userId).name;
      
      // オプション1: ユーザーを完全に削除
      // users.delete(userId);
      
      // オプション2: オフラインにマーク（再接続する可能性がある場合）
      users.get(userId).isOnline = false;
      
      console.log(`ユーザー切断: ${userName} (${userId})`);
      
      // 切断メッセージをブロードキャスト
      broadcast({
        id: uuidv4(),
        senderId: 'system',
        content: `${userName}さんが退室しました。`,
        timestamp: new Date().toISOString()
      });
      
      // ユーザーリストを更新
      broadcastUserList();
    }
  });
  
  // エラーハンドリング
  ws.on('error', (error) => {
    console.error(`WebSocketエラー (${userId}):`, error);
  });

  // Ping/Pongの処理（接続維持）
  ws.isAlive = true;
  ws.on('pong', () => {
    ws.isAlive = true;
  });
});

// 接続維持のための定期的なping
const interval = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) return ws.terminate();
    
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

// サーバー終了時のクリーンアップ
wss.on('close', () => {
  clearInterval(interval);
});

// サーバーの起動
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`WebSocketチャットサーバーが起動しました。ポート: ${PORT}`);
});