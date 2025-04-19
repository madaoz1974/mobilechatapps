# Dockerfile
FROM node:18-alpine

# アプリケーションディレクトリを作成
WORKDIR /usr/src/app

# パッケージ情報をコピー
COPY package*.json ./

# 依存関係をインストール
RUN npm install

# アプリケーションのソースをコピー
COPY . .

# アプリケーションが使用するポートを公開
EXPOSE 8080

# アプリケーションを実行
CMD [ "node", "server.js" ]