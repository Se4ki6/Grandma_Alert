# GenerateSignedURL Lambda関数の使い方

**作成日:** 2026年1月23日  
**対象モジュール:** `Lambda/GenerateSignedURL`

---

## 目次

1. [概要](#概要)
2. [仕組みの解説](#仕組みの解説)
3. [アーキテクチャ](#アーキテクチャ)
4. [前提条件](#前提条件)
5. [初期セットアップ](#初期セットアップ)
6. [Lambda関数のテスト実行](#lambda関数のテスト実行)
7. [使用方法](#使用方法)
8. [トラブルシューティング](#トラブルシューティング)
9. [FAQ（よくある質問）](#faqよくある質問)

---

## 概要

**GenerateSignedURL Lambda関数**は、CloudFront経由でS3バケットに保存されているダッシュボードや画像ファイルへの**一時的かつ安全なアクセス**を提供するためのサービスです。

### 主な機能

- CloudFront署名付きURLの生成
- 有効期限の設定（1分〜24時間）
- ワイルドカード対応（`/*`で全ファイルアクセス）
- HTTPSエンドポイント（Lambda Function URL）

### 使用シーン

1. **ダッシュボードへの認証付きアクセス**
2. **画像の一時的な共有**
3. **プライベートコンテンツへの制限付きアクセス**

---

## 仕組みの解説

### CloudFront署名付きURLとは？

CloudFront署名付きURLは、特定の時間だけコンテンツにアクセスできる「期限付きチケット」のようなものです。

**通常のURL（誰でもアクセス可能）:**

```
https://de4pssyxudete.cloudfront.net/index.html
```

**署名付きURL（期限内のみアクセス可能）:**

```
https://de4pssyxudete.cloudfront.net/index.html?Expires=1769929253&Signature=UFk-ldtzr...&Key-Pair-Id=APKAU55MGHO3FZXCUDQA
```

#### URLパラメータの意味

| パラメータ    | 説明                               | 例                     |
| ------------- | ---------------------------------- | ---------------------- |
| `Expires`     | アクセス期限（Unixタイムスタンプ） | `1769929253`           |
| `Signature`   | CloudFront秘密鍵で生成された署名   | `UFk-ldtzr...`         |
| `Key-Pair-Id` | CloudFront公開鍵のID               | `APKAU55MGHO3FZXCUDQA` |

### 署名生成の流れ

```
1. ユーザーがLambda Function URLにリクエスト
   ↓
2. Lambda関数がSSMパラメータストアから秘密鍵を取得
   ↓
3. 秘密鍵とKey Pair IDでURLに署名
   ↓
4. 署名付きURLをユーザーに返す
   ↓
5. ユーザーがCloudFrontにアクセス
   ↓
6. CloudFrontが公開鍵で署名を検証
   ↓
7. 検証成功 → S3からコンテンツを取得して返す
   検証失敗 → 403 Forbiddenエラー
```

### セキュリティの仕組み

#### 1. **非対称暗号化（公開鍵・秘密鍵）**

- **秘密鍵**: Lambda関数がSSMに保存（署名生成に使用）
- **公開鍵**: CloudFrontが保持（署名検証に使用）

→ 秘密鍵を持つLambda関数だけが有効な署名を作れる

#### 2. **時間制限**

- URLには有効期限が埋め込まれる
- 期限切れ後は自動的に無効化

#### 3. **SSMパラメータストアの暗号化**

- 秘密鍵は`SecureString`として暗号化保存
- 取得にはIAM権限が必要

#### 4. **IAMロールによるアクセス制御**

```
Lambda関数 → SSM読み取り権限のみ
SSMパラメータ → 特定のLambda関数のみアクセス可能
```

---

## アーキテクチャ

### システム構成図

```
┌─────────────────┐
│   ユーザー       │
└────────┬────────┘
         │ ① HTTPSリクエスト
         │ POST /
         │ {"path": "/index.html"}
         ↓
┌─────────────────────────────────┐
│ Lambda Function URL             │
│ (認証なし: NONE)                │
└────────┬────────────────────────┘
         │
         │ ② Lambda実行
         ↓
┌────────────────────────────────────────┐
│ GenerateSignedURL Lambda関数            │
│ ┌────────────────────────────────────┐ │
│ │ 1. 環境変数から設定取得            │ │
│ │    - CLOUDFRONT_DOMAIN             │ │
│ │    - CLOUDFRONT_KEY_PAIR_ID        │ │
│ │    - PRIVATE_KEY_SSM_PARAM         │ │
│ │                                    │ │
│ │ 2. SSMから秘密鍵を取得             │ │
│ │    ↓                               │ │
│ │ 3. CloudFrontSignerで署名生成      │ │
│ │    - URL + 有効期限 → 署名         │ │
│ └────────────────────────────────────┘ │
└────────┬───────────────────────────────┘
         │ ③ SSM読み取り
         │
         ↓
┌────────────────────────────────┐
│ AWS Systems Manager (SSM)      │
│ Parameter Store                │
│ ┌────────────────────────────┐ │
│ │ /cloudfront/private-key    │ │
│ │ (SecureString - 暗号化)    │ │
│ │                            │ │
│ │ -----BEGIN RSA PRIVATE KEY--│ │
│ │ MIIEpAIBAAKCAQEA...       │ │
│ │ -----END RSA PRIVATE KEY----│ │
│ └────────────────────────────┘ │
└────────────────────────────────┘
         │
         │ ④ 署名付きURL返却
         ↓
┌─────────────────┐
│   ユーザー       │ ⑤ 署名付きURLでアクセス
└────────┬────────┘
         │ GET https://de4pssyxudete.cloudfront.net/
         │     index.html?Expires=...&Signature=...
         ↓
┌────────────────────────────────────┐
│ CloudFront Distribution            │
│ ┌────────────────────────────────┐ │
│ │ 1. 署名検証                    │ │
│ │    - Key Pair IDで公開鍵取得   │ │
│ │    - 署名が正しいか確認        │ │
│ │    - 有効期限が切れていないか  │ │
│ │                                │ │
│ │ 2. 検証成功 → S3からファイル取得│ │
│ │    検証失敗 → 403エラー        │ │
│ └────────────────────────────────┘ │
└────────┬───────────────────────────┘
         │ ⑥ S3ファイル取得
         ↓
┌────────────────────────────────┐
│ S3 Bucket: grandma-alert-      │
│            dashboard-xxxxx     │
│ ┌────────────────────────────┐ │
│ │ index.html                 │ │
│ │ error.html                 │ │
│ │ /assets/...                │ │
│ └────────────────────────────┘ │
└────────────────────────────────┘
         │
         │ ⑦ コンテンツ配信
         ↓
┌─────────────────┐
│   ユーザー       │
└─────────────────┘
```

### コンポーネントの役割

| コンポーネント          | 役割                    | 技術スタック        |
| ----------------------- | ----------------------- | ------------------- |
| **Lambda Function URL** | HTTPSエンドポイント提供 | AWS Lambda          |
| **Lambda関数**          | 署名付きURL生成ロジック | Python 3.11         |
| **SSM Parameter Store** | 秘密鍵の安全な保管      | AWS Systems Manager |
| **CloudFront**          | CDN + 署名検証          | AWS CloudFront      |
| **S3 Bucket**           | 静的ファイル保管        | AWS S3              |
| **IAM Role**            | アクセス権限管理        | AWS IAM             |

### データフロー

```
リクエスト:
{
  "path": "/index.html",
  "expiration_minutes": 60
}
      ↓
Lambda処理:
- URL作成: https://de4pssyxudete.cloudfront.net/index.html
- 有効期限: 現在時刻 + 60分
- 署名生成: RSA-SHA1(URL + 有効期限)
      ↓
レスポンス:
{
  "signed_url": "https://de4pssyxudete.cloudfront.net/index.html?Expires=...&Signature=...&Key-Pair-Id=...",
  "expires_at": "2026-02-01T07:56:00",
  "expires_in_minutes": 60
}
```

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
cd ../../S3/Dashboard
terraform output cloudfront_domain_name
```

---

## Lambda関数のテスト実行

デプロイ後、Lambda関数が正常に動作することを確認します。

### 方法1: AWS Consoleでテスト

#### 手順:

1. **AWS Lambda コンソールを開く**
   - https://console.aws.amazon.com/lambda/
   - リージョン: ap-northeast-1

2. **関数を選択**
   - 関数名: `GenerateSignedURL`

3. **テストイベントを作成**
   - 「テスト」タブをクリック
   - 「新しいイベント」を選択
   - イベント名: `test-index-html`
   - イベントJSON:

   ```json
   {
     "path": "/index.html",
     "expiration_minutes": 60
   }
   ```

4. **テストを実行**
   - 「テスト」ボタンをクリック
   - 実行結果を確認

#### 期待される結果:

```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*"
  },
  "body": "{\"signed_url\":\"https://de4pssyxudete.cloudfront.net/index.html?Expires=...\",\"expires_at\":\"2026-02-01T12:00:00\",\"expires_in_minutes\":60}"
}
```

### 方法2: AWS CLIでテスト

#### 基本テスト（index.htmlの署名付きURL生成）:

```bash
aws lambda invoke \
  --function-name GenerateSignedURL \
  --payload '{"path": "/index.html", "expiration_minutes": 60}' \
  --region ap-northeast-1 \
  --profile default \
  response.json

# 結果を確認
cat response.json
```

#### ワイルドカードテスト（全ファイルアクセス可能な署名付きURL）:

```bash
aws lambda invoke \
  --function-name GenerateSignedURL \
  --payload '{"path": "/*", "expiration_minutes": 120}' \
  --region ap-northeast-1 \
  --profile default \
  response.json

cat response.json
```

### 方法3: Lambda Function URLでテスト

デプロイ後に自動生成されるHTTPSエンドポイントを使用します。

#### Function URLの取得:

```bash
cd Lambda/GenerateSignedURL
terraform output lambda_function_url
```

出力例: `https://abcd1234efgh5678.lambda-url.ap-northeast-1.on.aws/`

#### curlでテスト:

```bash
curl -X POST "https://lih3ewzwi2ftx4axh7opridr4q0ktmlr.lambda-url.ap-northeast-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"path": "/index.html", "expiration_minutes": 60}'
```

#### PowerShellでテスト:

```powershell
$url = "https://lih3ewzwi2ftx4axh7opridr4q0ktmlr.lambda-url.ap-northeast-1.on.aws/"
$body = @{
    path = "/index.html"
    expiration_minutes = 60
} | ConvertTo-Json

Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
```

### 方法4: 生成された署名付きURLをブラウザでテスト

1. 上記のいずれかの方法で署名付きURLを生成
2. レスポンスから`signed_url`をコピー
3. ブラウザのアドレスバーに貼り付けてアクセス
4. CloudFrontのダッシュボード（index.html）が表示されることを確認

---

## トラブルシューティング

### エラー: "Failed to generate signed URL"

**原因:**

- SSMパラメータストアに秘密鍵が保存されていない
- Lambda IAMロールにSSM読み取り権限がない
- CloudFront Key Pair IDが間違っている

**解決策:**

```bash
# SSMパラメータを確認
aws ssm get-parameter --name "/cloudfront/private-key" --with-decryption --region ap-northeast-1

# Lambda関数の環境変数を確認
aws lambda get-function-configuration --function-name GenerateSignedURL --region ap-northeast-1
```

### エラー: "No valid credential sources found"

**原因:** AWS認証情報が設定されていない

**解決策:**

```bash
# AWS CLIの設定
aws configure --profile default

# または環境変数で設定
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-1"
```

### 署名付きURLにアクセスすると403エラー

**原因:**

- CloudFrontディストリビューションに信頼されたキーグループが設定されていない
- Key Pair IDが一致していない

**解決策:**

1. S3/Dashboardのcloudfront.tfを確認
2. `trusted_key_groups`が正しく設定されているか確認
3. terraform applyでCloudFrontを再デプロイ

---

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

## FAQ（よくある質問）

### Q1: 署名付きURLは再利用できますか？

**A:** はい、有効期限内であれば何度でも使用可能です。ただし、URLを共有すると誰でもアクセスできるため注意が必要です。

### Q2: 有効期限を過ぎたURLはどうなりますか？

**A:** CloudFrontが`403 Forbidden`エラーを返します。新しい署名付きURLを生成してください。

### Q3: Lambda関数のコールドスタートはどのくらいですか？

**A:** 初回実行時は約600-700ms、その後は100-200ms程度です。SSMパラメータ取得は初回のみで、その後はメモリにキャッシュされます。

### Q4: 複数のファイルに同時にアクセスしたい場合は？

**A:** `path`パラメータに`/*`を指定すると、ワイルドカードで全ファイルにアクセス可能な署名付きURLが生成されます。

```powershell
$body = @{
    path = "/*"
    expiration_minutes = 30
} | ConvertTo-Json

Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
```

### Q5: CloudFront Key Pairは何個まで作れますか？

**A:** AWSアカウントごとに**2つ**までです。ルートユーザーのみ作成可能です。

### Q6: 秘密鍵をローテーションする頻度は？

**A:** セキュリティベストプラクティスとして、**90日〜180日**ごとの定期的なローテーションを推奨します。

### Q7: Lambda Function URLは誰でもアクセスできてしまいますか？

**A:** はい、現在は`authorization_type = "NONE"`のため誰でもアクセス可能です。本番環境では以下の対策を推奨：

- API Gateway + Cognito認証
- Lambda Function URLのIAM認証
- WAF（Web Application Firewall）の導入

### Q8: 署名付きURLのサイズ制限は？

**A:** URLは通常2000文字以内に収まります。ブラウザの制限（約2048文字）を超えることはほぼありません。

### Q9: Lambda関数のコストはどのくらいですか？

**A:**

- **リクエスト料金**: $0.20 / 100万リクエスト
- **実行時間料金**: $0.0000166667 / GB秒
- **月1,000回実行の場合**: 約 **$0.01以下**（ほぼ無料）

### Q10: SSMパラメータストアの料金は？

**A:**

- **Standard パラメータ**: 無料（10,000個まで）
- **取得API呼び出し**: $0.05 / 10,000回
- **このプロジェクトでは実質無料**

### Q11: cryptographyライブラリのエラーが出る場合は？

**A:** Windowsでビルドしたパッケージは、Lambda（Linux環境）では動作しません。`lambda.tf`で以下のオプションを指定してください：

```bash
pip install -r requirements.txt -t package/ --platform manylinux2014_x86_64 --only-binary=:all: --python-version 3.11
```

### Q12: 署名付きURLをキャッシュしても良いですか？

**A:** はい、有効期限内であればキャッシュ推奨です。以下の方法があります：

- **ブラウザ**: LocalStorage / SessionStorage
- **サーバー**: Redis / DynamoDB
- **注意**: 期限切れチェックを実装してください

### Q13: CloudFront Key Pairを削除するとどうなりますか？

**A:** **既存の署名付きURLは全て無効**になり、403エラーになります。新しいKey Pairを作成して再デプロイが必要です。

### Q14: 特定のIPアドレスからのみアクセスさせたい場合は？

**A:** CloudFront署名付きURLには「カスタムポリシー」を使用します。以下のパラメータを追加：

```python
# lambda_function.py で実装
cloudfront_signer.generate_presigned_url(
    url,
    date_less_than=expire_date,
    policy={
        "IpAddress": {"AWS:SourceIp": "203.0.113.0/24"}
    }
)
```

### Q15: Lambda関数のログはどこで確認できますか？

**A:** CloudWatch Logsで確認できます：

```bash
aws logs tail /aws/lambda/GenerateSignedURL --follow \
  --region ap-northeast-1 \
  --profile "AdministratorAccess-339126664118"
```

または、AWSコンソール → CloudWatch → ロググループ → `/aws/lambda/GenerateSignedURL`

---

## 次のステップ

1. **認証機能の追加** → API Gateway + Cognitoの統合
2. **モニタリングの設定** → CloudWatch Dashboard作成
3. **テストコードの作成** → Pytestでユニットテスト
4. **CI/CDパイプライン** → GitHub Actions / AWS CodePipeline

---

## 用語集

| 用語                    | 説明                                                        |
| ----------------------- | ----------------------------------------------------------- |
| **CloudFront**          | AWSのCDN（コンテンツ配信ネットワーク）                      |
| **署名付きURL**         | 有効期限とアクセス制限を持つ一時的なURL                     |
| **SSM Parameter Store** | AWS Systems Managerの機密情報管理サービス                   |
| **Lambda Function URL** | Lambda関数に直接HTTPSアクセスできる機能                     |
| **Key Pair**            | 公開鍵と秘密鍵のペア（非対称暗号化）                        |
| **IAM Role**            | AWSリソースへのアクセス権限を定義                           |
| **Terraform**           | インフラをコードで管理するツール（IaC）                     |
| **CORS**                | Cross-Origin Resource Sharing（異なるドメイン間の通信許可） |

---

## サポート

質問や問題がある場合:

- [GitHub Issues](https://github.com/your-repo/issues)
- プロジェクトドキュメント: [docs/](../../../docs/)
- S3 Dashboard実装: [S3/Dashboard/docs/](../../../S3/Dashboard/docs/)

---

**最終更新日:** 2026年2月1日
