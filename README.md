# 🚨 Grandma Alert (高齢者緊急通報システム) — 開発者向けREADME

新人参加者がすぐに開発へ参加できるよう、現時点の進捗と作業導線を整理しています。

## 1. プロジェクト概要

高齢者の緊急時に、家族のLINEグループへ「気づくまで画像を送り続ける（通知の嵐）」ことで迅速な初動対応を実現するシステムです。

### 主要コンセプト

- **Continuous Alert:** 5秒間隔で画像を送信
- **Flex Message Control:** 通報の通知メッセージにボタンを埋め込み、「通報」「解除」を即時操作
- **Multi-View:** 複数カメラはWebダッシュボードで一覧監視

> **アーキテクチャ変更メモ（2026/02/14）:**
> 当初はLINEリッチメニューで操作UIを提供する設計でしたが、
> 撮影通知のFlex Messageにボタンを埋め込む方式に変更しました。
> これにより、リッチメニューの設定・管理が不要になりました。

## 2. 仕様・設計ドキュメント

- 全体設計: [docs/Project/Design/Design.md](docs/Project/Design/Design.md)
- 要件/ロードマップ: [docs/Project/Design/RDD.md](docs/Project/Design/RDD.md)
- プロジェクト概要（ステークホルダー向け）: [docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)
- LT発表資料: [docs/LT.md](docs/LT.md)

## 3. 現在の進捗（2026/04/27時点）

### ✅ 完了

- LINE Developers コンソール設定
  - Messaging APIのチャネル作成
  - Webhook URL設定
  - 家族グループLINE作成 & Bot招待
- AWS IoT Core
  - Thing作成: `ElderlyCam_01`
  - 証明書発行 & ダウンロード
  - IoT Policy作成 & アタッチ
- S3バケット作成
  - Images Bucket（画像保存用・プライベート・ライフサイクル設定済み）
  - Dashboard Bucket（静的Webホスティング用）
- CloudFront ディストリビューション
  - OAC設定済み
  - 署名付きURL対応
- Lambda関数（全4関数デプロイ済み）
  - `GenerateSignedURL`：CloudFront署名付きURL生成
  - `FetchGroupID`：LINE Group ID取得
  - `LineNotification`：S3トリガー → Flex Message（画像 + 3ボタン）をLINEグループへ送信
  - `MessageHandle`：Flex MessageのPostbackを受け取り、通報情報送信 or Device Shadow更新
- AWS Secrets Manager
  - 通報情報の安全な格納（名前、住所、病歴）
  - Lambda関数からのアクセス設定
- Raspberry Pi環境構築・スクリプト実装
  - OS・Python環境セットアップ
  - AWS IoT SDK統合（MQTT通信）
  - カメラモジュール連携
  - 物理ボタン（Zigbee）監視
  - Device Shadow同期
  - 撮影・S3アップロード機能
- API Gateway（HTTP API）
  - MessageHandle用Webhookエンドポイント（POST /webhook）

### ⏳ 実装中

- Webダッシュボード（HTMLは実装済み・JS機能強化中）

### 🔜 未着手

- システム統合テスト（避難訓練）
- 運用設定（自動起動 / ログローテーション）

## 4. リポジトリ構成

```
.
├── README.md                         # このファイル
├── requirements.txt                  # Pythonパッケージ依存関係
│
├── docs/                             # ドキュメント
│   ├── PROJECT_OVERVIEW.md           # ステークホルダー向け概要
│   ├── LT.md                         # LT発表資料
│   ├── Project/
│   │   ├── Design/
│   │   │   ├── Design.md             # 全体設計ドキュメント
│   │   │   ├── LINE_Batch_Notification.md
│   │   │   └── RDD.md                # 要件/ロードマップ
│   │   └── Problems/
│   │       ├── FIXME_Review.md
│   │       ├── Issues.md
│   │       └── TODO.md
│   └── Setup/
│       ├── aws-cli-setup.md
│       ├── secret_files.md
│       ├── security-implementation.md
│       └── terraform-setup.md.md
│
├── AWS/IotCore/                          # AWS IoT Core基盤(Terraform)
│   ├── iot.tf
│   ├── output.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   ├── variable.tf
│   └── certs/                        # IoT Thing証明書（gitignore対象）
│
├── AWS/Lambda/                           # Lambda関数群
│   ├── FetchGroupID/                 # LINE groupId取得Lambda
│   │
│   ├── GenerateSignedURL/            # CloudFront署名付きURL生成Lambda
│   │   ├── lambda_function.py
│   │   ├── lambda.tf
│   │   └── docs/
│   │
│   ├── LineNotification/             # S3トリガー → LINEへFlex Message送信
│   │   ├── lambda.tf
│   │   └── python/
│   │       └── line.py
│   │
│   ├── MessageHandle/                # Postback処理Lambda + API Gateway
│   │   ├── apigateway.tf
│   │   ├── lambda.tf
│   │   └── lambda_code/
│   │       └── postback_handler.py
│   │
│   └── RichMenuHandle/               # リッチメニュー管理スクリプト（参考用）
│
├── AWS/Raspberrypi/                      # Raspberry Pi関連
│   ├── IAM/                          # RasPi用IAMロール(Terraform)
│   └── Script/                       # RasPi実行スクリプト
│       └── src/
│
├── AWS/S3/                               # S3バケット群
│   ├── Dashboard/                    # Webダッシュボード用S3+CloudFront
│   │   └── upload_file/              # デプロイするHTML/CSS/JS
│   │
│   └── Images/                       # 画像保存用S3+CloudFront
│
└── AWS/SecretsManager/                   # 秘匿情報管理(Terraform)
```

## 5. 新人向けスタートガイド（最短）

### Step 1: ドキュメント把握

1. [docs/Project/Design/Design.md](docs/Project/Design/Design.md) を通読（全体像）
2. [docs/Project/Design/RDD.md](docs/Project/Design/RDD.md) でロードマップ確認

### Step 2: セットアップ

ローカル準備の手順はドキュメントに整理しています。

- Terraformのインストール手順: [docs/Setup/terraform-setup.md.md](docs/Setup/terraform-setup.md.md)
- AWS CLIのインストールと初期設定（基本 + SSO）: [docs/Setup/aws-cli-setup.md](docs/Setup/aws-cli-setup.md)
- .gitignore対象の秘匿ファイル配布先: [docs/Setup/secret_files.md](docs/Setup/secret_files.md)

SSO利用時は、CLIプロファイルを指定して作業します（例: `$AWS_PROFILE` を設定）。

### Step 3: 各Terraformディレクトリを確認

| ディレクトリ | 内容 |
|---|---|
| [AWS/IotCore/](AWS/IotCore/) | IoT Core基盤（Thing・証明書・ポリシー） |
| [AWS/Lambda/LineNotification/](AWS/Lambda/LineNotification/) | S3トリガー → LINEへFlex Message送信 |
| [AWS/Lambda/MessageHandle/](AWS/Lambda/MessageHandle/) | Postback処理Lambda + API Gateway |
| [AWS/Lambda/GenerateSignedURL/](AWS/Lambda/GenerateSignedURL/) | CloudFront署名付きURL生成 |
| [AWS/S3/Images/](AWS/S3/Images/) | 画像保存バケット + CloudFront |
| [AWS/S3/Dashboard/](AWS/S3/Dashboard/) | Webダッシュボード + CloudFront |
| [AWS/SecretsManager/](AWS/SecretsManager/) | 通報情報の秘匿管理 |
| [AWS/Raspberrypi/](AWS/Raspberrypi/) | RasPiスクリプト + IAMロール |

### Step 4: 着手できるタスク

主要機能は実装済みです。以下のタスクが残っています。

1. **Webダッシュボードの機能強化**（JS自動リフレッシュ、複数カメラグリッド）
2. **システム統合テスト**（エンドツーエンドで通報フローを確認する避難訓練）
3. **運用設定**（Raspberry Piのsystemd自動起動、ログローテーション）

## 6. 開発の前提（設定値）

下記は `.gitignore` 対象の `terraform.tfvars` で管理しています。チームメンバーから受け取ってください。

- LINE Channel Access Token
- LINE Channel Secret
- LINE groupId
- AWS IoT Endpoint
- CloudFront キーペアID / 秘密鍵

## 7. TODO一覧

詳細は [docs/Project/Problems/TODO.md](docs/Project/Problems/TODO.md) を参照してください。

### Phase 1〜3: ✅ 完了

- ~~S3バケット作成 & ライフサイクル設定~~ ✅
- ~~Secrets Manager設定~~ ✅
- ~~RasPi: MQTT + Shadow監視 + 撮影/S3アップロード~~ ✅
- ~~Lambda: S3トリガー → LINE Flex Message通知~~ ✅
- ~~Lambda: LINE Webhook → Shadow更新 / 通報テンプレ送信~~ ✅
- ~~API Gateway + MessageHandle Lambda~~ ✅

### Phase 4: ⏳ 実装中

- Webダッシュボード機能強化（JS自動リフレッシュ / 複数カメラグリッド）

### Phase 5: 🔜 未着手

- システム統合テスト（避難訓練）
- 運用設定（自動起動、ログローテーション）

## 8. 運用メモ（重要）

- SDカード寿命対策（ログ量抑制）
- 電源抜け対策（AC固定 or モバイルバッテリー）
- CPU/熱対策（撮影5秒間隔で負荷増）

---

**次にやるべきことが分からない場合**は、[docs/Project/Design/RDD.md](docs/Project/Design/RDD.md) のフェーズ順で進めてください。
