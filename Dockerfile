# フロントエンドをビルド
FROM node:14 AS frontend
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# バックエンドをセットアップ
FROM python:3.10-slim AS backend
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ .

# Linux AMD64アーキテクチャ用のPython 3.10をベースとしたイメージを指定
FROM --platform=linux/amd64 python:3.10-slim

# Nginxのインストール
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# 必要なPythonパッケージをインストール
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Nginxの設定ファイルをコピー
COPY nginx.conf /etc/nginx/nginx.conf

# フロントエンドのビルド成果物をコピー
COPY --from=frontend /app/build /usr/share/nginx/html

# バックエンドのソースコードをコピー
COPY --from=backend /app /app

# 作業ディレクトリを設定
WORKDIR /app

# ポートを公開
EXPOSE 80 8000

# バックエンドとNginxを起動
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port 8000 & nginx -g 'daemon off;'"]
