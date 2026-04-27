# MessageHandle

## 概要

LINEリッチメニューからのPostbackアクションを受け取り、適切な処理を実行するLambda関数とAPI Gatewayを構築します。

**主な機能:**

- リッチメニューからの`report`アクション：Secrets Managerから通報情報を取得してLINEグループチャットにメッセージを送信
- リッチメニューからの`stop`アクション：通報停止メッセージを送信し、IoT CoreのDevice Shadowを更新

## 作成手順

### 前提条件

- LINE Messaging APIのチャネルが作成されていること
- リッチメニューが作成され、PostbackアクションのURLが設定可能な状態であること
- Secrets Managerに通報情報（`name`, `address`, `disease`）が登録されていること
- IoT CoreにThingが作成されていること

### デプロイ手順

1. `terraform.tfvars`を作成し、必要な変数を設定します（`sample.tfvars.example`を参考）：

   ```hcl
   profile                   = "your-profile"
   line_channel_access_token = "your-access-token"
   line_channel_secret       = "your-channel-secret"
   group_id                  = "your-group-id"
   thing_name                = "ElderlyCam_01"
   secret_name               = "LineRichMenu"
   ```

2. Terraformでデプロイ：

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. デプロイ後、outputに表示されるAPI GatewayのエンドポイントURLをLINE Developersコンソールで設定：
   - LINE Developersコンソールにログイン
   - チャネルの「Messaging API設定」タブを選択
   - 「Webhook URL」に `https://<API-Gateway-URL>/webhook` を設定
   - 「Webhookの利用」を有効化

## Lambda関数の処理内容

### `report`アクション

Secrets Managerから通報情報を取得し、以下のフォーマットでメッセージを送信：

```
119番する際は、次の内容を伝えてください。
===========================
救急です
名前は{name}で住所は{address}です。
既往症は{disease}です
```

### `stop`アクション

1. 「通報を停止しました」というメッセージをLINEグループチャットに送信
2. IoT CoreのDevice Shadowの`desired.status`を`"monitoring"`に更新

## アーキテクチャ構成

### Terraform構成

- **API Gateway (HTTP API)**：LINEからのPostback Webhookを受け取るエンドポイント（`POST /webhook`）
- **Lambda関数**：`postback_handler.py`でPostbackアクションを処理
- **IAM Role**：Secrets Manager読み取り、IoT Core Shadow更新、CloudWatch Logsへの書き込み権限
- **CloudWatch Logs**：Lambda関数のログ保持（1日間）

### 環境変数

| 変数名                      | 説明                                   |
| --------------------------- | -------------------------------------- |
| `LINE_CHANNEL_ACCESS_TOKEN` | LINEチャネルアクセストークン           |
| `LINE_CHANNEL_SECRET`       | LINEチャネルシークレット（署名検証用） |
| `GROUP_ID`                  | 送信先のLINEグループID                 |
| `SECRET_ID`                 | Secrets ManagerのシークレットID        |
| `THING_NAME`                | IoT CoreのThing名                      |

### 依存関係

- **Secrets Manager**：通報情報（name, address, disease）の取得
- **IoT Core**：Device Shadowの更新（stopアクション時）
- **LINE Messaging API**：Push APIでグループチャットにメッセージ送信

## セキュリティ

- LINE Webhookの署名検証（HMAC-SHA256）を実装
- チャネルシークレットを用いて、LINE公式からのリクエストであることを確認
- 不正なリクエストは`400 Bad Request`で拒否

## 依存関係図

```
┌─────────────┐
│  LINE User  │
│  (Family)   │
└──────┬──────┘
       │ Rich Menu
       │ POSTBACK
       ▼
┌─────────────────────────────────────┐
│   API Gateway (POST /webhook)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Lambda (postback_handler.py)       │
│                                     │
│  ├─ report action                   │
│  │  ├─ Secrets Manager (情報取得)   │
│  │  └─ LINE Message API (送信)      │
│  │                                  │
│  └─ stop action                     │
│     ├─ LINE Message API (送信)      │
│     └─ IoT Core (Shadow更新)        │
└─────────────────────────────────────┘
```

## トラブルシューティング

### Webhookが動作しない場合

1. CloudWatch Logsで`/aws/lambda/line_rich_menu_postback`のログを確認
2. LINE Developersコンソールで「Webhookの利用」が有効になっているか確認
3. API GatewayのURLが正しく設定されているか確認

### 署名検証エラーが発生する場合

- `LINE_CHANNEL_SECRET`が正しく設定されているか確認
- リクエストがLINE公式から送信されているか確認
