# LINE通知Lambda関数

## 概要
このモジュールは、AWS Lambdaを使用してLINE Messaging APIを通じてFlex Messageを送信するシステムです。Grandma_Alertプロジェクトの一部として、LINE Bot経由でグループに安否確認メニュー（3ボタン）を送信します。

## 主な機能
- **Flex Message送信**: リッチメニュー相当の3ボタンメニューをFlex Messageで送信
  - 通報する（Postback）
  - 画像一覧（URL遷移）
  - 大丈夫/停止する（Postback）
- **Lambda関数化**: サーバーレス環境での実行
- **CloudWatch Logs統合**: 実行ログの自動記録と監視
- **エラーハンドリング**: 実行時エラーの詳細なログ出力

## ファイル構成
```
LineNotification/
├── lambda.tf                # Lambda関数とIAM設定のTerraform定義
├── outputs.tf               # 出力値の定義
├── provider.tf              # プロバイダー設定
├── variable.tf              # 変数定義
├── terraform.tfvars.example # tfvarsのサンプル
├── python/
│   └── line.py              # LINE通知の実装コード
└── README.md                # このファイル
```

## デプロイ手順

### 1. tfvarsファイルを作成
`terraform.tfvars.example` をコピーして `terraform.tfvars` を作成し、値を設定します。

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. terraform.tfvars を編集
```hcl
profile                   = "your-aws-profile"
line_channel_access_token = "実際のLINEチャネルアクセストークン"
group_id                  = "Gから始まるグループID"
image_gallery_url         = "https://your-s3-bucket-url/index.html"
```

### 3. Terraformでデプロイ
```bash
terraform init
terraform plan
terraform apply
```

`terraform.tfvars` は `.gitignore` により Git 管理対象外です（シークレット保護）。

## Terraform変数一覧

| 変数名 | 説明 | デフォルト値 |
|--------|------|------------|
| `region` | AWSのリージョン名 | `ap-northeast-1` |
| `profile` | AWSのプロファイル名 | （必須） |
| `line_channel_access_token` | LINEチャネルのアクセストークン | （必須・sensitive） |
| `group_id` | 送信先のグループID（Gから始まるID） | （必須） |
| `image_gallery_url` | 画像一覧ページのURL | （必須） |

## ログ出力
Lambda関数はCloudWatch Logsに以下の情報を出力します：
- 関数の開始・終了
- 送信先ID
- APIレスポンスステータス
- エラー詳細（スタックトレース付き）

ログは[lambda.tf](lambda.tf)の設定に基づいて1日間保持されます。

## 関連リソース
- [Grandma_Alert README](../../README.md)
- [LINE Messaging API ドキュメント](https://developers.line.biz/ja/api-documentation/messaging-api/)
- [AWS Lambda Python ドキュメント](https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html)
