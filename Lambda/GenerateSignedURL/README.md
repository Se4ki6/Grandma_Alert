# GenerateSignedURL Lambda関数

CloudFront署名付きURLを生成するLambda関数です。ダッシュボードおよび画像への安全なアクセスを提供します。

## 機能

- CloudFront署名付きURLの生成
- 有効期限付きアクセス制御（デフォルト: 60分）
- SSMパラメータストアから秘密鍵を安全に取得
- Lambda Function URLによるHTTPSエンドポイント提供

## セットアップ手順

### 1. CloudFront Key Pairの作成

AWSマネジメントコンソールで以下の手順を実行：

1. **CloudFront Key Pairの生成**（ルートユーザーのみ可能）
   - AWSマネジメントコンソールにルートユーザーでログイン
   - 右上のアカウント名 → **セキュリティ認証情報** をクリック
   - **CloudFront キーペア** セクションに移動
   - **新しいキーペアを作成** をクリック
   - 秘密鍵（`.pem`ファイル）がダウンロードされる
   - Key Pair ID（例: `APKAXXXXXXXXXX`）をメモ

### 2. 秘密鍵をSSMパラメータストアに保存

```bash
# ダウンロードした秘密鍵をSSMに保存
aws ssm put-parameter \
  --name "/cloudfront/private-key" \
  --type "SecureString" \
  --value "file://pk-APKAXXXXXXXXXX.pem" \
  --region ap-northeast-1 \
  --profile default
```

### 3. terraform.tfvarsの設定

```terraform
cloudfront_domain      = "d1234567890abc.cloudfront.net"  # S3/Dashboard/cloudfront.tfのoutputから取得
cloudfront_key_pair_id = "APKAXXXXXXXXXX"                 # 手順1で取得したKey Pair ID
```

### 4. Terraformデプロイ

```bash
cd Lambda/GenerateSignedURL
terraform init
terraform plan
terraform apply
```

## 使用方法

### Lambda Function URLでリクエスト

```bash
# ダッシュボード全体へのアクセス
curl -X POST https://<lambda-function-url> \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/*",
    "expiration_minutes": 30
  }'

# 特定ファイルへのアクセス
curl -X POST https://<lambda-function-url> \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/index.html",
    "expiration_minutes": 10
  }'
```

### レスポンス例

```json
{
  "signed_url": "https://d1234567890abc.cloudfront.net/index.html?Expires=...&Signature=...&Key-Pair-Id=...",
  "expires_at": "2026-01-23T10:30:00",
  "expires_in_minutes": 60
}
```

## セキュリティ考慮事項

### 現在の設定（開発用）

- Lambda Function URLは認証なし（`authorization_type = "NONE"`）
- すべてのオリジンからのCORSを許可

### 本番環境への推奨改善

1. **API Gatewayの導入**
   - Lambda Function URLの代わりにAPI Gateway + Lambda統合
   - APIキー認証またはCognito認証

2. **VPC内配置**
   - Lambdaを専用VPC内に配置
   - Private SubnetからSSMアクセス

3. **CloudWatch Alarmsの設定**
   - エラー率の監視
   - 異常なリクエスト数の検知

## 依存関係

- **S3/Dashboard/cloudfront.tf**: CloudFrontディストリビューションのドメイン名が必要
- **AWS SSM Parameter Store**: CloudFront秘密鍵の保存先

## トラブルシューティング

### エラー: "Parameter not found"

秘密鍵がSSMに保存されていません。手順2を実行してください。

### エラー: "Invalid Key Pair ID"

`terraform.tfvars`のKey Pair IDが正しいか確認してください。

### URLが期限切れエラー

システム時刻が同期されているか確認してください（特にローカル環境）。

## 参考資料

- [CloudFront 署名付き URL の作成](https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-urls.html)
- [Lambda Function URLs](https://docs.aws.amazon.com/lambda/latest/dg/lambda-urls.html)
