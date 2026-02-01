# GenerateSignedURL Lambda関数

CloudFront署名付きURLを生成するLambda関数です。ダッシュボードおよび画像への安全なアクセスを提供します。

---

## 📋 目次

- [機能](#機能)
- [アーキテクチャ](#アーキテクチャ)
- [セットアップ手順](#セットアップ手順)
- [使用方法](#使用方法)
- [テスト方法](#テスト方法)
- [出力情報](#出力情報)
- [セキュリティ](#セキュリティ)
- [トラブルシューティング](#トラブルシューティング)

---

## 🚀 機能

- ✅ CloudFront署名付きURLの生成
- ✅ 有効期限付きアクセス制御（デフォルト: 60分、カスタマイズ可能）
- ✅ SSMパラメータストアから秘密鍵を安全に取得
- ✅ Lambda Function URLによるHTTPSエンドポイント提供
- ✅ ワイルドカード対応（`/*`で全ファイルアクセス）
- ✅ CORS対応

---

## 🏗️ アーキテクチャ

```
[クライアント]
    ↓ POST /
[Lambda Function URL]
    ↓
[GenerateSignedURL Lambda]
    ↓ 秘密鍵取得
[SSM Parameter Store]
    ↓ 署名付きURL生成
[クライアントへ返却]
    ↓ 署名付きURLでアクセス
[CloudFront] → [S3バケット]
```

## 📝 セットアップ手順

### 前提条件

- ✅ S3/Dashboardのデプロイ完了（CloudFrontドメインが必要）
- ✅ AWS CLI設定済み
- ✅ Terraform >= 1.0
- ✅ Python 3.x, pip

### 1. CloudFront Key Pairの作成

⚠️ **この手順はAWSルートユーザーのみ実行可能です**

1. AWSマネジメントコンソールに**ルートユーザー**でログイン
2. 右上のアカウント名 → **セキュリティ認証情報**
3. **CloudFront キーペア** → **新しいキーペアを作成**
4. 秘密鍵（`pk-APKAXXXXXXXXXX.pem`）をダウンロード
5. **Key Pair ID**（例: `APKAU55MGHO3FZXCUDQA`）をメモ

### 2. 秘密鍵をSSMパラメータストアに保存

#### AWS CLIの場合:

```bash
aws ssm put-parameter \
  --name "/cloudfront/private-key" \
  --type "SecureString" \
  --value file://pk-APKAXXXXXXXXXX.pem \
  --region ap-northeast-1 \
  --profile default
```

#### AWS Consoleの場合:

1. **Systems Manager** → **パラメータストア**
2. **パラメータの作成**をクリック
3. 設定:
   - 名前: `/cloudfront/private-key`
   - タイプ: `SecureString`
   - KMSキー: `alias/aws/ssm`
   - 値: 秘密鍵ファイルの内容を全てコピー&ペースト

###💻 使用方法

### Lambda Function URLの取得

```bash
terraform output lambda_function_url
```

出力例: `https://abcd1234.lambda-url.ap-northeast-1.on.aws/`

### リクエスト方法

#### curlの場合:

```bash
# index.htmlの署名付きURL生成（60分有効）
curl -X POST "https://abcd1234.lambda-url.ap-northeast-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"path": "/index.html", "expiration_minutes": 60}'

# 全ファイルアクセス可能な署名付きURL（120分有効）
curl -X POST "https://abcd1234.lambda-url.ap-northeast-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"path": "/*", "expiration_minutes": 120}'
```

#### PowerShellの場合:

```powershell
$url = "https://abcd1234.lambda-url.ap-northeast-1.on.aws/"
$body = @{
    path = "/index.html"
    expiration_minutes = 60
} | ConvertTo-Json

Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
```

### リクエストパラメータ

| パラメータ           | 型     | 必須 | デフォルト    | 説明                       |
| -------------------- | ------ | ---- | ------------- | -------------------------- |
| `path`               | string | ❌   | `/index.html` | CloudFront上のリソースパス |
| `expiration_minutes` | number | ❌   | `60`          | URL有効期限（分）          |

### レスポンス例

**成功時（200）:**

```json
{
  "signed_url": "https://de4pssyxudete.cloudfront.net/index.html?Expires=1706875200&Signature=abc123...&Key-Pair-Id=APKAU55MGHO3FZXCUDQA",
  "expires_at": "2026-02-01T12:00:00",
  "expires_in_minutes": 60
}
```

**エラー時（500）:**

```json
{
  "error": "Failed to generate signed URL",
  "message": "Parameter /cloudfront/private-key not found"
}
```

---

## 🧪 テスト方法

詳細な🔒 セキュリティ

### 現在の設定（開発・テスト用）

⚠️ **注意:** 以下は開発環境向けの設定です

- Lambda Function URLは認証なし（`authorization_type = "NONE"`）
- すべてのオリジンからのCORSを許可
- 公開エンドポイント（誰でもアクセス可能）

### 本番環境への推奨改善

#### 1. 認証の追加

**オプションA: API Gateway + Lambda統合**

```terraform
# API Gateway REST APIを使用
# - APIキー認証
# - Cognito User Pool認証
# - IAM認証
```

**オプションB: Lambda Function URL IAM認証**

```terraform
resource "aws_lambda_function_url" "signed_url_endpoint" {
  authorization_type = "AWS_IAM"  # IAM認証を有効化
}
```

#### 2. ネットワークセキュリティ

- VPC内にLambda配置
- Private SubnetからSSMアクセス
- NAT Gateway経由でインターネットアクセス

#### 3. レート制限

- API Gatewayの使用量プランで制限
- WAFでDDoS対策

#### 4. 監視とアラート

```bash
# CloudWatch Alarmsの設定例:
- Lambda Error Rate > 5%
- Lambda Concurrent Executions > 100
- SSM Parameter Access Denied
```

---

## 🔗 依存関係

| リソース            | 説明                                 | 取得方法                                    |
| ------------------- | ------------------------------------ | ------------------------------------------- |
| CloudFrontドメイン  | S3/Dashboardのディストリビューション | `cd ../../S3/Dashboard && terraform output` |
| SSM Parameter       | CloudFront秘密鍵の保存先             | 手動で作成（セットアップ手順参照）          |
| CloudFront Key Pair | 署名に使用                           | AWSルートユーザーで作成                     |

---

## 🐛 トラブルシューティング

### ❌ エラー: "Parameter /cloudfront/private-key not found"

**原因:** SSMパラメータストアに秘密鍵が保存されていない

**解決策:**

```bash
# パラメータの存在確認
aws ssm get-parameter --name "/cloudfront/private-key" --region ap-northeast-1

# 存在しない場合は作成（セットアップ手順2を実施）
```

### ❌ エラー: "Failed to generate signed URL"

**原因:**

- CloudFront Key Pair IDが間違っている
- 秘密鍵の形式が不正

**解決策:**

```bash
# Lambda環境変数を確認
aws lambda get-function-configuration \
  --function-name GenerateSignedURL \
  --region ap-northeast-1 \
  --query 'Environment.Variables'

# 秘密鍵の内容を確認
aws ssm get-parameter \
  --name "/cloudfront/private-key" \
  --with-decryption \
  --region ap-northeast-1
```

### ❌ 署名付きURLで403エラー

**原因:** CloudFrontディストリビューションに信頼されたキーグループが設定されていない

**解決策:**

1. [S3/Dashboard/cloudfront.tf](../../S3/Dashboard/cloudfront.tf) を確認
2. `trusted_key_groups`が正しく設定されているか確認
3. 必要に応じて再デプロイ:
   ```bash
   cd ../../S3/Dashboard
   terraform apply
   ```

### ❌ No valid credential sources found

**原因:** AWS認証情報が設定されていない

**解決策:**

```bash
# AWS CLIの設定
aws configure --profile default

# または環境変数で設定
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_DEFAULT_REGION="ap-northeast-1"
```

---

## 📚 関連ドキュメント

- [Implementation Guide](docs/implementation.md) - 実装の詳細
- [Usage Guide](docs/usage.md) - 詳細な使用方法とテスト
- [CloudFront 署名付き URL の作成](https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-urls.html)
- [Lambda Function URLs](https://docs.aws.amazon.com/lambda/latest/dg/lambda-urls.html)

---

## 📄 ライセンス

このプロジェクトは Grandma-Alert の一部です。

デプロイ完了後、以下の情報が出力されます:

- Lambda関数名
- Lambda Function URL（HTTPSエンドポイント）

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
