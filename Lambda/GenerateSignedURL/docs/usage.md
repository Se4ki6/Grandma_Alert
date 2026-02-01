# GenerateSignedURL Lambda関数の使い方

**作成日:** 2026年1月23日  
**対象モジュール:** `Lambda/GenerateSignedURL`

---

## 前提条件

### 必要なツール

- Terraform >= 1.0
- AWS CLI（認証設定済み）
- 適切なIAM権限
- CloudFront Key Pair（ルートユーザーで作成）

### 必要なIAM権限

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:CreateFunctionUrlConfig",
        "lambda:DeleteFunction",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "ssm:PutParameter",
        "ssm:GetParameter"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 初期セットアップ

### 1. CloudFront Key Pairの作成

⚠️ **重要:** この手順はルートユーザーのみ実行可能です。

#### 手順:

1. **AWSマネジメントコンソールにルートユーザーでログイン**
2. 右上のアカウント名 → **セキュリティ認証情報** をクリック
3. **CloudFront キーペア** セクションに移動
4. **新しいキーペアを作成** をクリック
5. 秘密鍵（`pk-APKAXXXXXXXXXX.pem`）がダウンロードされる
6. **Key Pair ID（例: `APKAXXXXXXXXXX`）をメモ**

### 2. 秘密鍵をSSMパラメータストアに保存

```bash
# ダウンロードした秘密鍵ファイルの場所に移動
cd ~/Downloads

# SSMパラメータストアに保存
aws ssm put-parameter \
  --name "/cloudfront/private-key" \
  --type "SecureString" \
  --value file://pk-APKAXXXXXXXXXX.pem \
  --region ap-northeast-1 \
  --profile your-aws-profile

# 確認
aws ssm get-parameter \
  --name "/cloudfront/private-key" \
  --with-decryption \
  --region ap-northeast-1 \
  --profile your-aws-profile
```

### 3. terraform.tfvars の設定

`Lambda/GenerateSignedURL/terraform.tfvars` を作成・編集:

```terraform
region                 = "ap-northeast-1"
profile                = "your-aws-profile"
cloudfront_domain      = "d1234567890abc.cloudfront.net"  # S3/DashboardのCloudFrontドメイン
cloudfront_key_pair_id = "APKAXXXXXXXXXX"                 # 手順1で取得したKey Pair ID

tags = {
  Project     = "Grandma-Alert"
  Environment = "production"
  ManagedBy   = "Terraform"
}
```

**cloudfront_domainの取得方法:**

```bash
# S3/Dashboardディレクトリで実行
cd ../../S3/Dashboard
terraform output cloudfront_domain_name
```

---

## デプロイ手順

### 初回デプロイ

```bash
# ディレクトリに移動
cd /path/to/Grandma_Alert/Lambda/GenerateSignedURL

# Terraform初期化
terraform init

# 実行計画の確認
terraform plan

# デプロイ実行
terraform apply
```

確認プロンプトで `yes` を入力してデプロイを実行します。

### デプロイ完了後

出力値を確認:

```bash
terraform output
```

**出力例:**

```
lambda_function_name = "generate-signed-url"
lambda_function_arn = "arn:aws:lambda:ap-northeast-1:123456789012:function:generate-signed-url"
lambda_function_url = "https://xyz123.lambda-url.ap-northeast-1.on.aws/"
lambda_execution_role_arn = "arn:aws:iam::123456789012:role/lambda-execution-role"
```

**Lambda Function URL をメモしてください。**

---

## 使用方法

### 基本的な使い方

#### 1. ダッシュボード全体へのアクセス

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

#### 2. 特定ファイルへのアクセス

```bash
curl -X POST https://xyz123.lambda-url.ap-northeast-1.on.aws/ \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/index.html",
    "expiration_minutes": 60
  }'
```

#### 3. 画像ファイルへのアクセス

```bash
curl -X POST https://xyz123.lambda-url.ap-northeast-1.on.aws/ \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/camera1/2026-01-23/image.jpg",
    "expiration_minutes": 10
  }'
```

### リクエストパラメータ

| パラメータ           | 型      | 必須 | デフォルト値  | 説明                                 |
| -------------------- | ------- | ---- | ------------- | ------------------------------------ |
| `path`               | string  | ❌   | `/index.html` | CloudFrontで配信するリソースのパス   |
| `expiration_minutes` | integer | ❌   | `60`          | URL有効期限（分）。1〜1440（24時間） |

**pathの例:**

- `/index.html` - ダッシュボードのトップページ
- `/*` - ダッシュボード全体（ワイルドカード）
- `/camera1/image.jpg` - 特定の画像
- `/assets/style.css` - CSSファイル

---

## ブラウザでの使用

### JavaScriptから呼び出す

```javascript
async function getSignedUrl(path = "/index.html", expirationMinutes = 60) {
  const response = await fetch(
    "https://xyz123.lambda-url.ap-northeast-1.on.aws/",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        path: path,
        expiration_minutes: expirationMinutes,
      }),
    },
  );

  const data = await response.json();
  return data.signed_url;
}

// 使用例
getSignedUrl("/*", 30).then((signedUrl) => {
  console.log("Signed URL:", signedUrl);
  window.location.href = signedUrl; // ダッシュボードにリダイレクト
});
```

### ダッシュボードへの自動リダイレクト

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Grandma Alert - Access</title>
  </head>
  <body>
    <h1>ダッシュボードにアクセスしています...</h1>

    <script>
      (async () => {
        try {
          const response = await fetch(
            "https://xyz123.lambda-url.ap-northeast-1.on.aws/",
            {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                path: "/*",
                expiration_minutes: 30,
              }),
            },
          );

          const data = await response.json();
          window.location.href = data.signed_url;
        } catch (error) {
          console.error("Error:", error);
          document.body.innerHTML = "<h1>アクセスエラー</h1>";
        }
      })();
    </script>
  </body>
</html>
```

---

## 動作確認

### 1. Lambda関数のテスト

```bash
# Lambda関数を直接呼び出し（AWS CLIで）
aws lambda invoke \
  --function-name generate-signed-url \
  --payload '{"path": "/index.html", "expiration_minutes": 60}' \
  --region ap-northeast-1 \
  --profile your-aws-profile \
  response.json

# レスポンスを確認
cat response.json
```

### 2. 署名付きURLの検証

```bash
# 生成された署名付きURLにアクセス
SIGNED_URL="<response.jsonから取得したsigned_url>"
curl -I "$SIGNED_URL"
```

**期待する結果:**

```
HTTP/2 200
content-type: text/html
x-cache: Miss from cloudfront
```

### 3. 有効期限の確認

```bash
# 有効期限切れのURLにアクセス（エラーになるべき）
# 時間を待つか、expiresパラメータを過去に設定してテスト
```

**期待する結果:**

```
HTTP/2 403
```

---

## トラブルシューティング

### 問題1: Lambda Function URLにアクセスできない

**エラーメッセージ:**

```
Could not resolve host: xyz123.lambda-url.ap-northeast-1.on.aws
```

**原因:** Lambda Function URLが作成されていない

**解決策:**

```bash
# Lambda Function URLを確認
aws lambda get-function-url-config \
  --function-name generate-signed-url \
  --region ap-northeast-1

# 存在しない場合は再デプロイ
terraform apply
```

### 問題2: SSMパラメータが見つからない

**エラーメッセージ:**

```
ParameterNotFound: Parameter /cloudfront/private-key not found
```

**原因:** SSMパラメータストアに秘密鍵が保存されていない

**解決策:**

```bash
# パラメータの存在確認
aws ssm get-parameter \
  --name "/cloudfront/private-key" \
  --region ap-northeast-1

# 存在しない場合は再度保存
aws ssm put-parameter \
  --name "/cloudfront/private-key" \
  --type "SecureString" \
  --value file://pk-APKAXXXXXXXXXX.pem \
  --region ap-northeast-1
```

### 問題3: 署名検証エラー（403 Forbidden）

**エラーメッセージ:**

```
HTTP/2 403
MissingKey: The specified key does not exist
```

**原因1:** CloudFront DistributionにKey Pairが関連付けられていない

**解決策:**

```bash
# CloudFront Distributionの設定を確認
aws cloudfront get-distribution-config \
  --id E1ABCDEFGHIJK \
  --region us-east-1
```

**原因2:** Key Pair IDが誤っている

**解決策:**

```bash
# terraform.tfvarsのcloudfront_key_pair_idを確認
cat terraform.tfvars | grep cloudfront_key_pair_id

# CloudFrontコンソールで正しいKey Pair IDを確認
```

### 問題4: Lambda実行エラー（ModuleNotFoundError）

**エラーメッセージ:**

```
ModuleNotFoundError: No module named 'cryptography'
```

**原因:** 依存ライブラリが含まれていない

**解決策:**

```bash
# Lambda Layerを作成
mkdir -p layer/python
pip install -r requirements.txt -t layer/python

# Layerをデプロイ（Terraformに追加）
# 詳細はissues.mdの問題7を参照
```

### 問題5: CORS エラー

**エラーメッセージ（ブラウザコンソール）:**

```
Access to fetch at '...' from origin 'https://example.com' has been blocked by CORS policy
```

**原因:** CORSの `allow_origins` に呼び出し元のドメインが含まれていない

**解決策:**

```terraform
# lambda.tf を編集
cors {
  allow_origins = ["https://example.com", "https://yourdomain.com"]
  allow_methods = ["POST"]
  allow_headers = ["content-type"]
}

# 再デプロイ
terraform apply
```

---

## 日常的な運用

### ログの確認

#### CloudWatch Logs

```bash
# 最新のログを表示
aws logs tail /aws/lambda/generate-signed-url --follow

# 特定期間のログを取得
aws logs filter-log-events \
  --log-group-name /aws/lambda/generate-signed-url \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --end-time $(date -u +%s)000
```

#### CloudWatch Logs Insights

```bash
# AWSコンソールでCloudWatch Logs Insightsを開く
# 以下のクエリを実行

# エラーログのみ抽出
fields @timestamp, @message
| filter @message like /Error/
| sort @timestamp desc
| limit 20

# 成功率の計算
stats count(*) as total,
      count(*) - count(statusCode != 200) as success
| extend success_rate = success / total * 100
```

### メトリクスの確認

#### Lambda関数のメトリクス

```bash
# 実行回数
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=generate-signed-url \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# エラー数
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=generate-signed-url \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# 平均実行時間
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=generate-signed-url \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

---

## Lambda関数の更新

### コードの変更

```bash
# lambda_function.pyを編集
vim lambda_function.py

# Terraformで再デプロイ
terraform apply
```

### 環境変数の変更

```bash
# terraform.tfvarsを編集
vim terraform.tfvars

# 変更を適用
terraform apply
```

### 依存ライブラリの更新

```bash
# requirements.txtを編集
vim requirements.txt

# Lambda Layerを再作成（手動）
pip install -r requirements.txt -t layer/python
zip -r layer.zip layer/

# Terraformで再デプロイ
terraform apply
```

---

## セキュリティベストプラクティス

### 1. 秘密鍵のローテーション

#### 手順:

1. **新しいCloudFront Key Pairを作成**（ルートユーザー）
2. **新しい秘密鍵をSSMに保存**

```bash
aws ssm put-parameter \
  --name "/cloudfront/private-key-new" \
  --type "SecureString" \
  --value file://pk-NEW-KEYPAIR.pem \
  --region ap-northeast-1
```

3. **terraform.tfvarsを更新**

```terraform
cloudfront_key_pair_id = "NEW-KEYPAIR-ID"
```

4. **Terraformで再デプロイ**

```bash
terraform apply
```

5. **古いKey Pairを無効化**

### 2. Lambda Function URLのアクセス制限

⚠️ **注意:** 現在は認証なし（`authorization_type = "NONE"`）

**推奨対応:**

- API Gatewayの導入
- Cognito認証
- IAM認証

詳細は [issues.md](issues.md) の問題1を参照

---

## リソースの削除

### 注意事項

- Lambda関数とロールが削除される
- CloudWatch Logsは残る（手動で削除可能）
- SSMパラメータは削除されない

### 削除手順

```bash
# すべてのリソースを削除
terraform destroy

# 確認プロンプトで yes を入力
```

**SSMパラメータの削除（オプション）:**

```bash
aws ssm delete-parameter \
  --name "/cloudfront/private-key" \
  --region ap-northeast-1
```

---

## ベストプラクティス

### 1. 有効期限の設定

**推奨値:**

- **ダッシュボード全体（`/*`）:** 30-60分
- **個別画像:** 5-10分
- **長時間セッション:** 最大1440分（24時間）

**理由:**

- 短すぎる → ユーザー体験の低下
- 長すぎる → セキュリティリスク

### 2. エラーハンドリング

```javascript
async function getSignedUrlWithRetry(path, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch("https://xyz123.lambda-url.../", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ path }),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      return data.signed_url;
    } catch (error) {
      console.error(`Attempt ${i + 1} failed:`, error);
      if (i === maxRetries - 1) throw error;
      await new Promise((resolve) => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}
```

### 3. キャッシング

```javascript
// ブラウザLocalStorageにキャッシュ
function cacheSignedUrl(path, signedUrl, expiresAt) {
  localStorage.setItem(
    `signed_url:${path}`,
    JSON.stringify({
      url: signedUrl,
      expires: expiresAt,
    }),
  );
}

function getCachedSignedUrl(path) {
  const cached = localStorage.getItem(`signed_url:${path}`);
  if (!cached) return null;

  const { url, expires } = JSON.parse(cached);
  if (new Date(expires) < new Date()) {
    localStorage.removeItem(`signed_url:${path}`);
    return null;
  }

  return url;
}
```

---

## 関連コマンド一覧

### Terraform

```bash
# 初期化
terraform init

# 実行計画
terraform plan

# デプロイ
terraform apply

# 削除
terraform destroy

# 出力値確認
terraform output

# 状態確認
terraform show

# 特定リソースの詳細
terraform state show aws_lambda_function.generate_signed_url
```

### AWS CLI

```bash
# Lambda関数一覧
aws lambda list-functions --region ap-northeast-1

# Lambda関数の詳細
aws lambda get-function --function-name generate-signed-url

# Lambda関数の呼び出し
aws lambda invoke \
  --function-name generate-signed-url \
  --payload '{"path": "/index.html"}' \
  response.json

# CloudWatch Logs
aws logs tail /aws/lambda/generate-signed-url --follow

# SSMパラメータ確認
aws ssm get-parameter --name "/cloudfront/private-key"
```

---

## 次のステップ

1. **認証機能の追加** → [issues.md](issues.md) の問題1参照
2. **モニタリングの設定** → [issues.md](issues.md) の問題10参照
3. **テストコードの作成** → [issues.md](issues.md) の問題11参照

---

## サポート

質問や問題がある場合:

- [GitHub Issues](https://github.com/your-repo/issues)
- プロジェクトドキュメント: [docs/](../../../docs/)
- S3 Dashboard実装: [S3/Dashboard/docs/](../../../S3/Dashboard/docs/)
