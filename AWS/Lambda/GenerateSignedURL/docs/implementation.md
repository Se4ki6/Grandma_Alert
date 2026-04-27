# GenerateSignedURL Lambda関数の実装内容と特徴

**作成日:** 2026年1月23日  
**対象モジュール:** `Lambda/GenerateSignedURL`

---

## 概要

Grandma Alertプロジェクトにおける、CloudFront署名付きURLを生成するLambda関数です。ダッシュボードおよび画像への安全なアクセス制御を提供します。

---

## リソース構成

### 1. Lambda関数

#### 1.1 メイン関数 (`aws_lambda_function.generate_signed_url`)

- **ランタイム:** Python 3.11
- **メモリ:** 128MB
- **タイムアウト:** 30秒
- **ハンドラー:** `lambda_function.lambda_handler`

**環境変数:**

```terraform
environment {
  variables = {
    CLOUDFRONT_DOMAIN         = var.cloudfront_domain
    CLOUDFRONT_KEY_PAIR_ID    = var.cloudfront_key_pair_id
    PRIVATE_KEY_SSM_PARAM     = "/cloudfront/private-key"
    URL_EXPIRATION_MINUTES    = "60"
  }
}
```

#### 1.2 Lambda Function URL (`aws_lambda_function_url.generate_signed_url`)

- **認証タイプ:** NONE（開発用）
- **CORS設定:** すべてのオリジンを許可
- **HTTPSエンドポイント:** 自動生成

**CORS設定:**

```terraform
cors {
  allow_origins  = ["*"]
  allow_methods  = ["POST"]
  allow_headers  = ["content-type"]
  max_age        = 86400
}
```

### 2. IAMロール

#### 2.1 実行ロール (`aws_iam_role.lambda_execution`)

**信頼ポリシー:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### 2.2 基本実行ポリシー

- **AWSLambdaBasicExecutionRole:** CloudWatch Logsへの書き込み権限

#### 2.3 SSMアクセスポリシー (`aws_iam_role_policy.ssm_access`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ssm:GetParameter", "ssm:GetParameters"],
      "Resource": "arn:aws:ssm:*:*:parameter/cloudfront/private-key"
    }
  ]
}
```

- **目的:** SSMパラメータストアからCloudFront秘密鍵を取得
- **アクセス範囲:** `/cloudfront/private-key` パラメータのみ

### 3. デプロイメント

#### 3.1 ソースコードアーカイブ (`data.archive_file.lambda_zip`)

```terraform
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/"
  output_path = "${path.module}/lambda_function.zip"

  excludes = [
    "*.tf",
    "*.tfvars",
    "*.md",
    ".terraform",
    "lambda_function.zip",
    "docs"
  ]
}
```

**含まれるファイル:**

- `lambda_function.py`
- `requirements.txt`（依存ライブラリ）

#### 3.2 依存ライブラリ

**requirements.txt:**

```
cryptography>=41.0.0
boto3>=1.34.0
```

- **cryptography:** RSA署名生成
- **boto3:** AWS SDK（SSM, CloudFront操作）

---

## Lambda関数の実装詳細

### コア機能

#### 1. 署名付きURL生成

```python
def lambda_handler(event, context):
    # リソースパスを取得（デフォルト: /index.html）
    resource_path = body.get('path', '/index.html')
    expiration_minutes = body.get('expiration_minutes', URL_EXPIRATION_MINUTES)

    # CloudFront URLを構築
    url = f"https://{CLOUDFRONT_DOMAIN}{resource_path}"

    # 有効期限を設定
    expire_date = datetime.utcnow() + timedelta(minutes=expiration_minutes)

    # 署名付きURLを生成
    cloudfront_signer = CloudFrontSigner(CLOUDFRONT_KEY_PAIR_ID, rsa_signer)
    signed_url = cloudfront_signer.generate_presigned_url(
        url,
        date_less_than=expire_date
    )
```

#### 2. RSA署名生成

```python
def rsa_signer(message):
    # SSMから秘密鍵を取得（初回のみ、以降はキャッシュ）
    if not hasattr(rsa_signer, 'private_key'):
        response = ssm.get_parameter(Name=PRIVATE_KEY_SSM_PARAM, WithDecryption=True)
        private_key_pem = response['Parameter']['Value']

        rsa_signer.private_key = serialization.load_pem_private_key(
            private_key_pem.encode('utf-8'),
            password=None,
            backend=default_backend()
        )

    # メッセージに署名
    signature = rsa_signer.private_key.sign(
        message,
        padding.PKCS1v15(),
        hashes.SHA1()
    )
    return signature
```

**最適化:**

- 秘密鍵は初回のみSSMから取得
- 以降は関数の静的変数にキャッシュ
- コールドスタート後の2回目以降のリクエストで高速化

### リクエスト形式

#### POSTリクエスト

```json
{
  "path": "/index.html",
  "expiration_minutes": 60
}
```

**パラメータ:**

- `path` (string, オプション): CloudFrontで配信するリソースパス
  - デフォルト: `/index.html`
  - ワイルドカード対応: `/*`
- `expiration_minutes` (integer, オプション): URL有効期限（分）
  - デフォルト: 60分

#### レスポンス形式

```json
{
  "signed_url": "https://d1234567890abc.cloudfront.net/index.html?Expires=1706000000&Signature=...&Key-Pair-Id=APKA...",
  "expires_at": "2026-01-23T10:30:00",
  "expires_in_minutes": 60
}
```

### エラーハンドリング

```python
except Exception as e:
    print(f"Error generating signed URL: {str(e)}")
    return {
        'statusCode': 500,
        'body': json.dumps({
            'error': 'Internal server error',
            'message': str(e)
        })
    }
```

---

## 主要な特徴

### 🔒 セキュリティ

1. **秘密鍵の安全な管理**
   - SSMパラメータストア（SecureString）に保存
   - Lambda内でのみ復号化
   - 環境変数には保存しない

2. **有効期限付きアクセス**
   - デフォルト60分で自動失効
   - カスタマイズ可能

3. **CloudFront署名検証**
   - CloudFront側で署名を自動検証
   - 改ざん検知

### ⚡ パフォーマンス

1. **秘密鍵キャッシング**
   - 初回のみSSMアクセス
   - 以降はメモリキャッシュ

2. **軽量なランタイム**
   - メモリ: 128MB
   - 平均実行時間: 100-200ms

3. **Lambda Function URL**
   - API Gateway不要（低レイテンシ）
   - 直接HTTPSエンドポイント

### 🛠️ 運用性

1. **環境変数による設定**
   - CloudFrontドメイン
   - Key Pair ID
   - デフォルト有効期限

2. **CloudWatch Logs統合**
   - すべてのリクエストをログ記録
   - エラートレース

3. **Terraformによる管理**
   - コードベースのインフラ管理
   - バージョン管理

---

## 変数定義

| 変数名                   | 型            | 説明                   | 必須 |
| ------------------------ | ------------- | ---------------------- | ---- |
| `region`                 | `string`      | AWSリージョン          | ✅   |
| `profile`                | `string`      | AWS認証プロファイル    | ✅   |
| `cloudfront_domain`      | `string`      | CloudFrontドメイン名   | ✅   |
| `cloudfront_key_pair_id` | `string`      | CloudFront Key Pair ID | ✅   |
| `tags`                   | `map(string)` | リソースに付与するタグ | ❌   |

**デフォルトタグ:**

```terraform
tags = {
  Project   = "Grandma-Alert"
  ManagedBy = "Terraform"
}
```

---

## 出力値

| 出力名                      | 説明                |
| --------------------------- | ------------------- |
| `lambda_function_name`      | Lambda関数名        |
| `lambda_function_arn`       | Lambda関数ARN       |
| `lambda_function_url`       | Lambda Function URL |
| `lambda_execution_role_arn` | Lambda実行ロールARN |

---

## アーキテクチャ図

```
[クライアント]
    |
    | HTTPS POST
    ↓
[Lambda Function URL]
    |
    | 署名付きURL生成
    ↓
[Lambda: GenerateSignedURL]
    |
    | SSM GetParameter
    ↓
[SSM Parameter Store]
    └── /cloudfront/private-key

[Lambda]
    |
    | 署名付きURL返却
    ↓
[クライアント]
    |
    | 署名付きURLでアクセス
    ↓
[CloudFront]
    |
    | 署名検証 → 成功
    ↓
[S3: Dashboard/Images]
```

---

## 技術的な工夫

### 1. CloudFront Signerの実装

**署名アルゴリズム:**

- RSA-SHA1
- PKCS#1 v1.5 パディング

**CloudFront署名付きURL形式:**

```
https://domain.cloudfront.net/resource?
  Expires=1706000000&
  Signature=base64_encoded_signature&
  Key-Pair-Id=APKAXXXXXXXXXX
```

### 2. SSMパラメータストアの活用

**メリット:**

- 秘密鍵の一元管理
- KMS暗号化
- アクセス制御（IAMポリシー）
- 監査ログ（CloudTrail）

**代替案との比較:**

| 方式                   | セキュリティ | 管理性 | コスト |
| ---------------------- | ------------ | ------ | ------ |
| SSM Parameter Store    | ⭐⭐⭐       | ⭐⭐⭐ | ⭐⭐⭐ |
| Secrets Manager        | ⭐⭐⭐       | ⭐⭐⭐ | ⭐     |
| 環境変数（暗号化なし） | ⭐           | ⭐⭐⭐ | ⭐⭐⭐ |
| S3バケット             | ⭐⭐         | ⭐⭐   | ⭐⭐   |

### 3. 関数のステートレス設計

- 各リクエストは独立
- 秘密鍵のキャッシュは静的変数で実現
- スケーラビリティ確保

---

## 使用例

### 1. ダッシュボード全体へのアクセス

```bash
curl -X POST https://xyz123.lambda-url.ap-northeast-1.on.aws/ \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/*",
    "expiration_minutes": 30
  }'
```

**レスポンス:**

```json
{
  "signed_url": "https://d1234567890abc.cloudfront.net/*?Expires=1706001800&Signature=...&Key-Pair-Id=APKA...",
  "expires_at": "2026-01-23T10:30:00",
  "expires_in_minutes": 30
}
```

### 2. 特定ファイルへのアクセス

```bash
curl -X POST https://xyz123.lambda-url.ap-northeast-1.on.aws/ \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/index.html",
    "expiration_minutes": 10
  }'
```

### 3. 画像ファイルへのアクセス

```bash
curl -X POST https://xyz123.lambda-url.ap-northeast-1.on.aws/ \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/camera1/2026-01-23/image.jpg",
    "expiration_minutes": 5
  }'
```

---

## セキュリティ考慮事項

### 現在の設定（開発用）

⚠️ **注意:** 以下は開発環境向けの設定です

- Lambda Function URLは認証なし（`authorization_type = "NONE"`）
- すべてのオリジンからのCORSを許可（`allow_origins = ["*"]`）

### 本番環境への推奨改善

#### 1. Lambda Function URLの認証

```terraform
authorization_type = "AWS_IAM"
```

- IAM認証を有効化
- Cognito Identity Pool経由でアクセス

#### 2. CORS制限

```terraform
allow_origins = ["https://yourdomain.com"]
```

#### 3. API Gatewayの導入

- Lambda Function URLの代わりにAPI Gateway
- APIキー認証
- レート制限
- カスタムドメイン

#### 4. VPC配置

```terraform
vpc_config {
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.lambda.id]
}
```

---

## 関連ドキュメント

- **使い方:** [usage.md](usage.md)
- **現状の問題点:** [issues.md](issues.md)
- **TODO:** [../../../docs/TODO.md](../../../docs/TODO.md)
- **設計書:** [../../../docs/Design.md](../../../docs/Design.md)
- **Dashboard実装:** [../../../S3/Dashboard/docs/implementation.md](../../../S3/Dashboard/docs/implementation.md)
