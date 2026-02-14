# 🚨 Grandma Alert (高齢者緊急通報システム) — 開発者向けREADME

新人参加者がすぐに開発へ参加できるよう、現時点の進捗と作業導線を整理しています。

## 1. プロジェクト概要

高齢者の緊急時に、家族のLINEグループへ「気づくまで画像を送り続ける（通知の嵐）」ことで迅速な初動対応を実現するシステムです。

### 主要コンセプト

- **Continuous Alert:** 5秒間隔で画像を送信
- **Rich Menu Control:** 通報/解除を固定メニューで即時操作
- **Multi-View:** 複数カメラはWebダッシュボードで一覧監視

## 2. 仕様・設計ドキュメント

- 全体設計: [docs/Design.md](docs/Design.md)
- 要件/ロードマップ: [docs/RDD.md](docs/RDD.md)

## 3. 現在の進捗（2026/02/14時点）

### ✅ 完了

- LINE Developers コンソール設定
  - Messaging APIのチャネル作成
  - Webhook URL設定（空でも可）
  - 家族グループLINE作成 & Bot招待
- AWS IoT Core
  - Thing作成: `ElderlyCam_01`
  - 証明書発行 & ダウンロード
  - IoT Policy作成 & アタッチ
- S3バケット作成
  - Images Bucket（画像保存用）
  - Dashboard Bucket（静的Webホスティング用）
- CloudFront ディストリビューション
  - OAC設定済み
  - 署名付きURL対応
- Lambda関数
  - GenerateSignedURL（署名付きURL生成）
  - FetchGroupID（Group ID取得）
  - LineNotification（LINE通知送信）
  - MessageHandle（リッチメニューPostback処理）
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

### ⏳ 一部実装中

- Webダッシュボード（基本実装完了、機能強化中）

### 🔜 未着手（これからの主要タスク）

- LINEリッチメニューのビジュアル作成・設定
- システム統合テスト・避難訓練
- 運用設定（自動起動、ログローテーション）

## 4. リポジトリ構成

```
.
├── README.md                         # このファイル
├── requirements.txt                  # Pythonパッケージ依存関係
│
├── docs/                             # ドキュメント
│   ├── PROJECT_OVERVIEW.md
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
├── IotCore/                          # AWS IoT Core基盤(Terraform)
│   ├── iot.tf
│   ├── output.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   ├── variable.tf
│   ├── terraform.tfstate
│   ├── terraform.tfstate.backup
│   └── certs/                        # IoT Thing証明書
│       ├── AmazonRootCA1.pem
│       ├── certificate.pem.crt
│       ├── private.pem.key
│       └── public.pem.key
│
├── Lambda/                           # Lambda関数群
│   ├── FetchGroupID/                 # LINE groupId取得Lambda
│   │   ├── terraform.tfstate
│   │   └── terraform.tfvars
│   │
│   ├── GenerateSignedURL/            # 署名付きURL生成Lambda
│   │   ├── lambda_function.py
│   │   ├── lambda.tf
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   ├── README.md
│   │   ├── requirements.txt
│   │   ├── terraform.tfstate
│   │   ├── terraform.tfstate.backup
│   │   ├── terraform.tfvars
│   │   ├── variables.tf
│   │   ├── docs/
│   │   │   ├── implementation.md
│   │   │   └── usage.md
│   │   └── package/                  # デプロイパッケージ
│   │
│   ├── LineNotification/             # LINE通知Lambda（画像送信）
│   │   ├── lambda.tf
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   ├── README.md
│   │   ├── terraform.tfstate
│   │   ├── terraform.tfstate.backup
│   │   ├── terraform.tfvars
│   │   ├── variable.tf
│   │   └── python/
│   │
│   ├── MessageHandle/                # Postback処理Lambda + API Gateway
│   │   ├── apigateway.tf
│   │   ├── lambda.tf
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   ├── README.md
│   │   ├── requirements.txt
│   │   ├── sample.tfvars.example
│   │   ├── terraform.tfstate
│   │   ├── terraform.tfstate.backup
│   │   ├── terraform.tfvars
│   │   ├── variable.tf
│   │   └── lambda_code/
│   │       └── postback_handler.py
│   │
│   └── RichMenuHandle/               # リッチメニュー作成・管理スクリプト
│       ├── terraform.tfvars
│       ├── lambda_code/
│       └── rich_menu/
│
├── Raspberrypi/                      # Raspberry Pi関連
│   ├── IAM/                          # RasPi用IAMロール(Terraform)
│   │   ├── iam.tf
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   ├── terraform.tfstate
│   │   ├── terraform.tfvars
│   │   └── variables.tf
│   └── Script/                       # RasPi実行スクリプト
│       ├── README.md
│       ├── requirements.txt
│       └── src/
│
├── S3/                               # S3バケット群
│   ├── Dashboard/                    # Webダッシュボード用S3+CloudFront
│   │   ├── cloudfront.tf
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   ├── README.md
│   │   ├── s3.tf
│   │   ├── terraform.tfstate
│   │   ├── terraform.tfstate.backup
│   │   ├── terraform.tfvars
│   │   ├── variables.tf
│   │   ├── docs/
│   │   └── upload_file/
│   │
│   └── Images/                       # 画像保存用S3+CloudFront
│       ├── cloudfront.tf
│       ├── download_sample_images.ps1
│       ├── outputs.tf
│       ├── provider.tf
│       ├── README.md
│       ├── s3.tf
│       ├── terraform.tfstate
│       ├── terraform.tfvars
│       ├── upload_test_images.ps1
│       ├── variables.tf
│       └── sample_images/
│
└── SecretsManager/                   # 秘匿情報管理(Terraform)
    ├── lambda_associate.md
    ├── provider.tf
    ├── README.md
    ├── sevretsmanager.tf
    ├── terraform.tfvars.template
    └── variables.tf
```

## 5. 新人向けスタートガイド（最短）

### Step 1: ドキュメント把握

1. [docs/Design.md](docs/Design.md) を通読（全体像）
2. [docs/RDD.md](docs/RDD.md) でロードマップ確認

### Step 2: Terraformディレクトリを確認

- [Lambda/FetchGroupID/](Lambda/FetchGroupID/) : LINEグループID取得用のAPIGateway/Lambda一式
- [Lambda/MessageHandle/](Lambda/MessageHandle/) : Postback処理Lambda + API Gateway
- [IotCore/](IotCore/) : IoT Core基盤の定義
- [Raspberrypi/](Raspberrypi/) : Raspberry Pi用スクリプトとIAM設定

### Step 2.5: セットアップ/チュートリアル

ローカル準備の手順はドキュメントに整理しています。該当するOSの手順に従ってください。

- Terraformのインストール手順: [docs/Setup/terraform-setup.md.md](docs/Setup/terraform-setup.md.md)
- AWS CLIのインストールと初期設定（基本 + SSO）: [docs/Setup/aws-cli-setup.md](docs/Setup/aws-cli-setup.md)
- .gitignore対象の秘匿ファイル配布先: [docs/Setup/secret_files.md](docs/Setup/secret_files.md)

SSO利用時は、CLIプロファイルを指定して作業します（例: `$AWS_PROFILE` を設定）。

### Step 3: TODOの中から着手しやすいもの

主要機能は実装済みです。以下の追加タスクに着手できます。

1. **LINEリッチメニューの画像作成・設定**
2. **Webダッシュボードの機能強化**
3. **システム統合テスト（避難訓練）**

## 6. 開発の前提（設定値）

下記はまだ確定していないため、作業の際は一時値 or .env で管理してください。

- LINE Channel Access Token
- LINE groupId
- AWS IoT Endpoint

## 7. TODO一覧（現状の抜粋）

詳細は [docs/Project/Design/Design.md](docs/Project/Design/Design.md) を参照してください。

### Phase 1-3: ✅ 完了

- ~~S3バケット作成 & ライフサイクル設定~~ ✅
- ~~Secrets Manager設定~~ ✅
- ~~RasPi: MQTT + Shadow監視 + 撮影/S3アップロード~~ ✅
- ~~Lambda: S3トリガー → LINE通知~~ ✅
- ~~Lambda: LINE Webhook → Shadow更新/通報テンプレ送信~~ ✅
- ~~API Gateway + MessageHandle Lambda~~ ✅

### Phase 4: ⏳ 実装中

- LINEリッチメニュー画像作成・設定
- Webダッシュボード機能強化

### Phase 5: 🔜 未着手

- システム統合テスト（避難訓練）
- 運用設定（自動起動、ログローテーション）

## 8. 運用メモ（重要）

- SDカード寿命対策（ログ量抑制）
- 電源抜け対策（AC固定 or モバイルバッテリー）
- CPU/熱対策（撮影5秒間隔で負荷増）

---

**次にやるべきことが分からない場合**は、[docs/RDD.md](docs/RDD.md) のフェーズ順で進めてください。
