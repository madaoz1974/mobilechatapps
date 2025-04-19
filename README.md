# mobilechatapps

# WebSocketチャットサーバーのコンテナ化手順

## 1. プロジェクト構成

以下のファイル構成でプロジェクトを作成します：

```
chat-server/
├── server.js        # WebSocketサーバーのメインコード
├── package.json     # 依存関係の定義
├── Dockerfile       # Dockerイメージの構築定義
└── docker-compose.yml # 複数コンテナの構成
```

## 2. package.jsonの作成

```bash
# プロジェクトディレクトリを作成
mkdir chat-server
cd chat-server

# package.jsonを初期化
npm init -y

# 必要なパッケージをインストール
npm install ws uuid
```

`package.json`を以下のように編集します：

```json
{
  "name": "websocket-chat-server",
  "version": "1.0.0",
  "description": "WebSocket Chat Server",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "ws": "^8.13.0",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
```

## 3. Dockerfileの作成

先ほど提供したDockerfileを作成します。

## 4. docker-compose.ymlの作成

先ほど提供したdocker-compose.ymlを作成します。

## 5. Dockerイメージの構築と実行

```bash
# Dockerイメージをビルド
docker-compose build

# コンテナをバックグラウンドで起動
docker-compose up -d

# ログを確認
docker-compose logs -f
```

## 6. SSL対応のためのNginxリバースプロキシ設定（オプション）

`wss://`プロトコルを使用するには、Nginxをリバースプロキシとして設定します。

docker-compose.ymlに以下を追加：

```yaml
  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - chat-server
```

Nginxの設定ファイル (`./nginx/conf.d/default.conf`) を作成：

```nginx
server {
    listen 443 ssl;
    server_name your-chat-server.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    location /chat {
        proxy_pass http://chat-server:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 7. 本番環境でのデプロイ

### Dockerホストへのデプロイ
```bash
# リモートサーバーにファイルを転送
scp -r chat-server user@your-server-ip:/path/to/deploy

# リモートサーバーでコンテナを起動
ssh user@your-server-ip "cd /path/to/deploy/chat-server && docker-compose up -d"
```

### Kubernetesへのデプロイ

Kubernetesを使用する場合は、以下のようなデプロイメントYAMLを作成します：

`chat-server-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: chat-server
  template:
    metadata:
      labels:
        app: chat-server
    spec:
      containers:
      - name: chat-server
        image: your-registry/chat-server:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: chat-server
spec:
  selector:
    app: chat-server
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
```

Kubernetesにデプロイ：
```bash
kubectl apply -f chat-server-deployment.yaml
```

## 8. メンテナンスとスケーリング

- **コンテナの状態確認**: `docker-compose ps`
- **ログ確認**: `docker-compose logs -f`
- **コンテナ再起動**: `docker-compose restart`
- **水平スケーリング**: `docker-compose up -d --scale chat-server=3`

# WebSocketチャットサーバーのセットアップ手順

## 1. 必要な環境の準備
- Node.js (v14以上推奨)
- npm (Node.jsに同梱)

## 2. プロジェクトの初期化

```bash
# 新しいディレクトリを作成
mkdir chat-server
cd chat-server

# プロジェクトを初期化
npm init -y

# 必要なパッケージをインストール
npm install ws uuid
```

## 3. server.jsファイルの作成

先ほど提供したコードを`server.js`というファイル名で保存します。

## 4. サーバーの起動

```bash
# サーバーを起動
node server.js
```

起動すると、ターミナルに「WebSocketチャットサーバーが起動しました。ポート: 8080」と表示されます。

## 5. SSL対応（本番環境向け）

実際の本番環境では、SSLを適用してwssプロトコルを使用する必要があります。以下はNode.jsでSSLを設定する基本的な方法です。

```javascript
const https = require('https');
const fs = require('fs');
const WebSocket = require('ws');

// SSL証明書を読み込む
const options = {
  key: fs.readFileSync('/path/to/private-key.pem'),
  cert: fs.readFileSync('/path/to/certificate.pem')
};

// HTTPSサーバーを作成
const server = https.createServer(options, (req, res) => {
  res.writeHead(200);
  res.end('Secure WebSocket Server');
});

// WebSocketサーバーを作成
const wss = new WebSocket.Server({ server });

// 同じイベントハンドラを設定...

// サーバーの起動（SSLはデフォルトで443ポート）
const PORT = process.env.PORT || 443;
server.listen(PORT, () => {
  console.log(`セキュアWebSocketサーバーが起動しました。ポート: ${PORT}`);
});
```

## 6. ドメイン設定

実際に`wss://your-chat-server.com/chat`として使用するには:

1. `your-chat-server.com`ドメインを取得
2. サーバーにドメインを設定
3. SSL証明書を取得してセキュアな接続を構成
4. DNSレコードを適切に設定

## 7. クライアント側の修正

SwiftUI側のコードで、WebSocketサーバーのURLを適切に変更します:

```swift
// 開発環境（ローカル）
serverURL = URL(string: "ws://localhost:8080/chat")!

// 本番環境
serverURL = URL(string: "wss://your-chat-server.com/chat")!
```

## 8. デプロイオプション

- **Heroku**: Procfileを作成しHerokuにデプロイ
- **AWS**: EC2インスタンスまたはElastic Beanstalkを使用
- **DigitalOcean**: Dropletを作成してデプロイ
- **Render.com**: WebServiceとしてデプロイ

## 9. サーバー監視と自動再起動

本番環境では、PM2などのプロセスマネージャーを使用してサーバーを監視・自動再起動することをお勧めします。

```bash
# PM2をグローバルにインストール
npm install -g pm2

# PM2でサーバーを起動
pm2 start server.js --name "chat-server"

# 自動起動設定
pm2 startup
pm2 save
```