# 🚨 高齢者緊急通報システム (RasPi版) 実装ToDo

## 📦 Phase 1: 環境構築 & AWS基盤

- [x] **LINE Developers コンソール設定**
  - [x] 新規プロバイダー・チャネル作成 (Messaging API)
  - [x] Channel Access Token (長期) の発行
    - [ ] z7KszMfu3sWs4cltxmaWi3/X7dQ6IGfNNu8+QV0nGxkYrHnQ4LEU2p9x0uiNRTTREgEdRE55wX6FaL7gBy8Dck6LAVnMgwxtn42h+X56ExuEKv8J0pCWEOTQAdHfLW/56ty3i+ZjTZlFy1s37edg9QdB04t89/1O/w1cDnyilFU=
  - [x] Webhook URLの設定 (一旦空欄でOK)
  - [x] 家族グループLINEの作成 & Bot招待
  - [x] `groupId` の取得 (ダミーイベントを叩かせてログから特定など)
    - [ ] `Cd0d26de7f9ed6ba055297c0d0253efad`
- [x] **AWS IoT Core セットアップ**
  - [x] モノ (Thing) の作成: `ElderlyCam_01`
  - [x] 証明書 (Cert, Private Key, Root CA) の発行 & ダウンロード
    - [ ] iot_endpoint = "[a2kvsxl8s30u6t-ats.iot.ap-northeast-1.amazonaws.com](http://a2kvsxl8s30u6t-ats.iot.ap-northeast-1.amazonaws.com/)"
  - [x] ポリシー作成 & アタッチ (Connect, Publish, Subscribe, Receive)
- [ ] **ストレージ & DB構築**
  - [ ] S3バケット作成 (画像保存用 & 静的Webホスティング用)
  - [ ] S3ライフサイクル設定 (古い画像を自動削除: eg. 1日後)
  - [ ] DynamoDBテーブル作成: `EmergencyInfo` (PK: `house_id`)
  - [ ] DynamoDBへのテストデータ投入 (住所、通報用テキスト等)

## 🥧 Phase 2: エッジデバイス (Raspberry Pi)

- [ ] **OS & 基本設定**
  - [ ] Raspberry Pi OS (Lite推奨) インストール
  - [ ] SSH接続有効化 & Wi-Fi設定
  - [ ] 固定IP化 (ルーター側設定推奨)
- [ ] **Python環境構築**
  - [ ] 必要なライブラリのインストール
    - `pip install awsiotsdk boto3 opencv-python RPi.GPIO`
  - [ ] 証明書ファイルの配置 (`/home/pi/certs/` 等)
- [ ] **物理実装**
  - [ ] カメラモジュール (or USB Webカメラ) 接続 & 動作確認
  - [ ] 物理ボタンのGPIO接続 & 入力検知テスト
- [ ] **アプリケーション実装 (main.py)**
  - [ ] AWS IoT Core 接続処理 (MQTT)
  - [ ] Device Shadow 監視ロジック (`delta` トピックのSubscribe)
  - [ ] **[Loop処理]** 物理ボタン監視 → Shadow更新 (`alert`)
  - [ ] **[Loop処理]** 撮影 → S3アップロード (5秒間隔 / 非同期推奨)
  - [ ] エラーハンドリング (ネットワーク切断時の再接続など)

## ☁️ Phase 3: クラウドロジック (Lambda)

- [ ] **通知システム (Notification Storm)**
  - [ ] Lambda関数作成: `NotifyFamily` (Runtime: Python 3.x)
  - [ ] トリガー設定: S3 `ObjectCreated`
  - [ ] 実装: 画像URLを含んだメッセージをLINE Messaging APIでPush
- [ ] **司令塔システム (Command Handler)**
  - [ ] Lambda関数作成: `HandleLineWebhook`
  - [ ] トリガー設定: API Gateway (HTTP API) → Webhook URLとしてLINEに登録
  - [ ] 実装: LINE署名検証
  - [ ] 実装: Postbackアクション分岐
    - `action=report`: DynamoDB参照 → テキスト送信
    - `action=safe`: Shadow更新 (`monitoring`) → システム停止通知

## 📱 Phase 4: UI & リッチメニュー

- [ ] **LINE リッチメニュー**
  - [ ] メニュー画像の作成 (通報 / 解除 / 一覧)
  - [ ] JSON定義の作成 (Action領域の指定)
  - [ ] Messaging API でリッチメニューを作成 & デフォルト設定
- [ ] **Web Dashboard (S3 Hosting)**
  - [ ] `index.html` 作成 (全カメラのグリッド表示)
  - [ ] JavaScript実装 (5秒ごとの画像リロード処理)
  - [ ] S3バケットポリシー設定 (特定IP制限 or 簡易認証推奨)

## 🧪 Phase 5: テスト & デプロイ

- [ ] **単体テスト**
  - [ ] ラズパイのボタンを押してShadowが `alert` に変わるか？
  - [ ] S3に画像を置いたらLINEに通知が飛ぶか？
- [ ] **結合テスト (避難訓練)**
  - [ ] ボタン押下 → 通知の嵐開始 → リッチメニューで解除 → 停止
  - [ ] ボタン押下 → リッチメニューで「通報」 → 正しい住所が出るか
- [ ] **運用設定**
  - [ ] ラズパイの自動起動設定 (`systemd` 登録)
  - [ ] ログローテーション設定 (SDカード保護)
