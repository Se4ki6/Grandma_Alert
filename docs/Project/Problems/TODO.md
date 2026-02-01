# Grandma Alert プロジェクト - TODO リスト

**最終更新:** 2026年2月1日  
**管理対象モジュール:** 全モジュール

---

## 📋 目次

1. [S3/Dashboard モジュール](#s3dashboard-モジュール)
2. [S3/Images モジュール](#s3images-モジュール)
3. [ダッシュボード ↔ S3/Images 連携](#ダッシュボード--s3images-連携)
4. [Lambda/GenerateSignedURL モジュール](#lambdageneratesignedurl-モジュール)
5. [Secrets Manager モジュール](#secrets-manager-モジュール)
6. [全体的な実装順序](#全体的な実装順序)

---

# S3/Dashboard モジュール

**レビュー日時:** 2026年1月22日

## 🚨 重大な問題（即座に対応が必要）

### 1. HTMLファイルが空

- [x] `S3/Dashboard/upload_file/index.html` の実装
- [x] `S3/Dashboard/upload_file/error.html` の実装
- **影響:** 現在、空ファイルがS3にアップロードされるため、静的Webサイトとして機能しない
- **優先度:** 🔴 高

---

## ⚠️ セキュリティ関連（本番環境前に対応）

### 2. パブリックアクセスの制限（署名付きURL方式）

**方針:** Basic認証なし、署名付きURLで一時的なアクセスを許可（緊急時の利便性を優先）

#### 実装手順

- [ｘ] **2.1 S3バケットをプライベート化**
  - [ｘ] `s3.tf` の `aws_s3_bucket_public_access_block` を変更
    ```terraform
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
    ```
  - [ｘ] `aws_s3_bucket_policy.dashboard_public` リソースを削除

- [ｘ] **2.2 CloudFront ディストリビューションの作成**
  - [ｘ] 新規ファイル `S3/Dashboard/cloudfront.tf` を作成
  - [ｘ] Origin Access Control (OAC) の設定
  - [ｘ] S3バケットポリシーにCloudFrontからのアクセスのみ許可
  - [ｘ] Cache設定（画像は5秒でキャッシュ無効化）

- [ｘ] **2.3 Lambda関数で署名付きURL生成**
  - [ｘ] 新規Lambda関数: `GenerateSignedURL`
  - [x] CloudFront Key Pair の作成（AWSコンソール → CloudFront → Key management）
  - [x] 署名付きURLの有効期限を設定（推奨: 10分〜1時間）
  - [x] Lambda実装:
    ```python
    # boto3でCloudFront署名付きURLを生成
    from botocore.signers import CloudFrontSigner
    ```

- [ ] **2.4 通知システムの修正**
  - [ ] `NotifyFamily` Lambda関数を修正
  - [ ] S3画像URLの代わりに、CloudFront署名付きURLを生成してLINE送信
  - [ ] URLの有効期限をメッセージに明示（例: "10分間有効"）

- [ ] **2.5 Dashboard アクセスの署名付きURL化**
  - [ ] API Gateway + Lambda でダッシュボード用署名付きURL発行エンドポイント作成
  - [ ] LINEリッチメニューに「ダッシュボードを開く」ボタン追加
  - [ ] ボタン押下 → 署名付きURL生成 → リダイレクト

- [ ] **2.6 テスト**
  - [ ] 署名なしアクセスが拒否されることを確認
  - [ ] 署名付きURLでアクセス成功を確認
  - [ ] URL有効期限切れ後のアクセス拒否を確認

- **現状:** すべてのリソースに完全パブリックアクセスを許可
- **優先度:** 🟡 中
- **推定工数:** 4-6時間

### 3. CORS設定の厳格化

- [ ] `allowed_origins` を特定のドメインに制限
- **現状:** `allowed_origins = ["*"]` で全ドメインを許可
- **推奨:** 実際に使用するドメインのみ許可
- **優先度:** 🟡 中
- **関連:** [Issues.md](Issues.md#問題2-cors設定が過度に緩い) - S3/Dashboard - 問題2

---

## 🔧 改善提案（品質向上）

### 4. バリデーション機能の追加

- [ ] Terraform に lifecycle precondition を追加
  ```terraform
  lifecycle {
    precondition {
      condition     = fileexists("${path.module}/upload_file/index.html")
      error_message = "index.html が存在しません"
    }
  }
  ```
- [ ] ファイルサイズのチェック（空ファイル検知）
- **効果:** デプロイ前に問題を検出できる
- **優先度:** 🟢 低
- **関連:** [Issues.md](Issues.md#問題4-バリデーション機能の不足) - S3/Dashboard - 問題4

### 5. タグ管理の統一

- [ ] すべてのリソースに `tags` 変数を適用
- [ ] 現在、`aws_s3_bucket.dashboard` のみタグを適用
- [ ] 他のリソース（versioning, CORS設定など）にも適用を検討
- **優先度:** 🟢 低
- **関連:** [Issues.md](Issues.md#問題5-タグ管理の不統一) - S3/Dashboard - 問題5

### 6. エラーハンドリングの強化

- [ ] HTMLファイルが存在しない場合の適切なエラーメッセージ
- [ ] `filemd5()` のエラーハンドリング追加
- **優先度:** 🟢 低
- **関連:** [Issues.md](Issues.md#問題6-エラーハンドリングの不足) - S3/Dashboard - 問題6

---

## 📝 実装すべき機能（index.html）

### 7. ダッシュボード機能の実装

- [ ] カメラ画像のグリッド表示UI
- [ ] 5秒ごとの自動画像リフレッシュ機能
- [ ] エラー時の適切な表示処理
- [ ] レスポンシブデザイン対応
- [ ] 画像読み込み失敗時のフォールバック表示
- **設計書要件:** 「全カメラのグリッド表示」「5秒ごとの画像リロード処理」
- **優先度:** 🔴 高
- **関連:** [Issues.md](Issues.md#問題9-ダッシュボードuiの機能不足) - S3/Dashboard - 問題9

### 8. エラーページの実装

- [ ] `error.html` の基本的なエラー表示
- [ ] 404, 403 などの適切なエラーメッセージ
- [ ] ホームページへの戻りリンク
- **優先度:** 🟡 中

---

## ✅ S3/Dashboard - 良好な実装（維持）

- ✓ リソース構成が適切（バケット、バージョニング、ポリシー、CORS設定）
- ✓ 静的Webサイトホスティング設定が正しく構成
- ✓ `depends_on` で依存関係を明示的に定義
- ✓ `etag` を使用してファイル変更を検知
- ✓ CORS設定の基本構成が適切

---

# S3/Images モジュール

**作成日:** 2026年2月1日

## 🚨 重大な問題（本番環境前に対応必須）

### 1. パブリックアクセスの無効化

- [ ] `S3/Images/s3.tf` の `aws_s3_bucket_public_access_block` を変更
  ```terraform
  block_public_acls       = true   # false → true
  block_public_policy     = true   # false → true
  ignore_public_acls      = true   # false → true
  restrict_public_buckets = true   # false → true
  ```
- [ ] `aws_s3_bucket_policy.images_public_read` を削除または制限
- [ ] 代替アクセス方式の実装（署名付きURLまたはCloudFront OAC）
- **現状:** テスト用にパブリックアクセスが有効
- **影響:** 画像URLを知っている人は誰でもアクセス可能
- **優先度:** 🔴 高
- **関連:** [Issues.md](Issues.md#-問題1-パブリックアクセスが有効テスト用設定のまま) - S3/Images - 問題1

### 2. CORS設定の厳格化

- [ ] `allowed_origins` をCloudFrontドメインに限定
  ```terraform
  allowed_origins = [
    "https://d2zaynqig5sahs.cloudfront.net",
    "https://<your-domain>.com"
  ]
  ```
- **現状:** `allowed_origins = ["*"]` で全ドメインを許可
- **優先度:** 🟡 中
- **関連:** [Issues.md](Issues.md#-問題2-cors設定が過度に緩い-1) - S3/Images - 問題2

---

## ✅ S3/Images - 良好な実装（維持）

- ✓ バケットバージョニングが有効
- ✓ サーバーサイド暗号化（AES256）が設定済み
- ✓ ライフサイクルポリシーで古い画像を自動削除
- ✓ Lambda通知用のS3イベント設定済み

---

# ダッシュボード ↔ S3/Images 連携

**作成日:** 2026年2月1日  
**対象ファイル:** `S3/Dashboard/upload_file/index.html`

## 🚨 重大な問題（機能が未完成）

### 1. 署名付きURL方式への移行

- [ ] `CONFIG.LAMBDA_SIGNED_URL_ENDPOINT` にLambda URLを設定
  ```javascript
  LAMBDA_SIGNED_URL_ENDPOINT: 'https://lih3ewzwi2ftx4axh7opridr4q0ktmlr.lambda-url.ap-northeast-1.on.aws/',
  ```
- [ ] `loadCameraImage()` 関数で署名付きURLを使用するように変更
- [ ] S3直接アクセスからの移行テスト
- **現状:** S3バケットに直接アクセス（パブリック読み取り）
- **影響:** セキュリティリスク、S3バケットをパブリックにする必要がある
- **優先度:** 🔴 高
- **関連:** [Issues.md](Issues.md#-問題3-s3直接アクセス方式のセキュリティリスク) - ダッシュボード連携 - 問題3

### 2. カメラリスト取得APIの実装

- [ ] Lambda関数 `ListCameras` の作成
  - [ ] S3 `listObjectsV2()` でカメラIDフォルダを取得
  - [ ] API GatewayまたはLambda Function URLの設定
- [ ] `loadCamerasFromS3()` 関数の実装
  ```javascript
  async function loadCamerasFromS3() {
    const response = await fetch(CONFIG.LIST_CAMERAS_ENDPOINT);
    const data = await response.json();
    cameras = data.cameras;
  }
  ```
- [ ] `index.html` に `LIST_CAMERAS_ENDPOINT` 設定を追加
- **現状:** `loadCamerasFromS3()` はデモデータ(`DEMO_CAMERAS`)にフォールバック
- **影響:** IoTデバイスから動的にアップロードされた画像を検出できない
- **優先度:** 🔴 高
- **関連:** [Issues.md](Issues.md#-問題1-カメラリスト取得機能が未実装) - ダッシュボード連携 - 問題1

### 3. 画像パス規則の文書化と標準化

- [ ] IoTデバイス側とのパス規則を合意
- [ ] 標準パス規則をドキュメント化
  ```
  {camera_id}/
  ├── latest.jpg           # 最新画像（常に上書き）
  ├── 2026/02/01/          # 履歴画像（オプション）
  │   ├── 10-30-00.jpg
  │   └── ...
  ```
- [ ] `index.html` のコメントに規則を記載
- **現状:** `{camera_id}/latest.jpg` を想定しているが未文書化
- **優先度:** 🟡 中
- **関連:** [Issues.md](Issues.md#-問題2-画像パス規則の未文書化) - ダッシュボード連携 - 問題2

### 4. エラーハンドリングの改善

- [ ] エラー種別に応じたメッセージ表示（403, 404等）
- [ ] リトライボタンの追加
- [ ] コンソールログの充実
- **優先度:** 🟢 低
- **関連:** [Issues.md](Issues.md#-問題4-画像取得エラー時のフォールバック処理が不十分) - ダッシュボード連携 - 問題4

---

## 📋 実装手順

### ステップ1: 署名付きURL方式への移行

1. `index.html` の `CONFIG.LAMBDA_SIGNED_URL_ENDPOINT` を設定
2. `loadCameraImage()` 関数を修正（署名付きURL使用）
3. S3 Images バケットのパブリックアクセスを無効化
4. 動作確認

### ステップ2: カメラリスト取得APIの実装

1. Lambda関数 `ListCameras` を作成
2. Lambda Function URLを設定
3. `index.html` の `loadCamerasFromS3()` を実装
4. 動作確認

---

## ✅ ダッシュボード連携 - 良好な実装（維持）

- ✓ 5秒ごとの自動リフレッシュ機能
- ✓ タイムスタンプ付与によるキャッシュバスター
- ✓ 画像読み込み失敗時の基本的なフォールバック表示
- ✓ レスポンシブデザイン対応
- ✓ 署名付きURL取得関数のフレームワーク準備済み

---

# Secrets Manager モジュール

**作成日:** 2026年2月1日  
**対象モジュール:** `SecretsManager/`

## ✅ Secrets Manager - 完了項目

- ✓ シークレット作成（LineRichMenu）
- ✓ 通報情報の格納（名前、住所、病歴）
- ✓ リソースポリシー設定
- ✓ Lambda関数からのアクセス許可設定
- ✓ Terraformによる管理

## 📋 設計方針

### DynamoDBからSecrets Managerへの移行理由

1. **セキュリティ強化**
   - KMS暗号化による保護
   - IAMポリシーによるきめ細かいアクセス制御
   - 監査ログ（CloudTrail）

2. **コスト最適化**
   - DynamoDB: $0.25/GB/月 + 読み取り/書き込みコスト
   - Secrets Manager: $0.40/シークレット/月（少量データに最適）

3. **運用簡素化**
   - 単一のシークレットで通報情報を管理
   - バージョン管理機能
   - 自動ローテーション（将来対応可能）

## 🔧 改善提案（品質向上）

### 1. シークレットのローテーション設定

- [ ] 自動ローテーションの設定
- [ ] ローテーションLambda関数の作成
- **優先度:** 🟢 低

### 2. 複数環境対応

- [ ] 環境別シークレット（dev/staging/prod）
- [ ] 命名規則の統一
- **優先度:** 🟢 低

---

# Lambda/GenerateSignedURL モジュール

**作成日:** 2026年1月23日

## 📋 実装の全体フロー

```
1. ✅ S3/Dashboard デプロイ
   └─ CloudFront Distribution: d2zaynqig5sahs.cloudfront.net

2. ✅ Lambda関数デプロイ完了
   └─ Lambda Function URL: https://lih3ewzwi2ftx4axh7opridr4q0ktmlr.lambda-url.ap-northeast-1.on.aws/

3. ✅ CloudFront Key Pair作成（ルートユーザー）

4. ✅ SSMに秘密鍵保存

5. ⬜ CloudFront署名検証設定

6. ⬜ 動作確認・テスト
```

---

## 現在のステータス

### ✅ 完了済み

- [x] S3バケット作成
- [x] CloudFront Distribution作成
- [x] ダッシュボードHTML実装
- [x] Lambda関数コード実装
- [x] Terraform設定ファイル作成
- [x] Lambda関数デプロイ
- [x] CloudFront Key Pair作成
- [x] SSMパラメータストアへの秘密鍵保存

### ⏸️ 保留中（署名検証設定待ち）

**確認URL:** https://d2zaynqig5sahs.cloudfront.net

**Lambda URL:** https://lih3ewzwi2ftx4axh7opridr4q0ktmlr.lambda-url.ap-northeast-1.on.aws/

---

## ⬜ 署名付きURL機能を有効にする手順

### 手順1: CloudFront Key Pair作成

⚠️ **ルートユーザーでの作業が必要**

```bash
# 手順:
1. AWSコンソールにルートユーザーでログイン
2. セキュリティ認証情報 → CloudFront キーペア
3. 新しいキーペアを作成
4. 秘密鍵をダウンロード（pk-APKAXXXXXXXXXX.pem）
5. Key Pair IDをメモ
```

**保存場所の提案:**

```bash
mkdir -p ~/secrets/grandma-alert/
mv ~/Downloads/pk-APKAXXXXXXXXXX.pem ~/secrets/grandma-alert/
chmod 600 ~/secrets/grandma-alert/pk-APKAXXXXXXXXXX.pem
```

---

### 手順2: SSMパラメータストアに保存

```bash
cd ~/secrets/grandma-alert/

# SSMに保存
aws ssm put-parameter \
  --name "/cloudfront/private-key" \
  --type "SecureString" \
  --value file://pk-APKAXXXXXXXXXX.pem \
  --region ap-northeast-1 \
  --profile AdministratorAccess-339126664118

# 確認
aws ssm get-parameter \
  --name "/cloudfront/private-key" \
  --with-decryption \
  --region ap-northeast-1 \
  --profile AdministratorAccess-339126664118
```

**期待される結果:**

```json
{
  "Parameter": {
    "Name": "/cloudfront/private-key",
    "Type": "SecureString",
    "Value": "-----BEGIN RSA PRIVATE KEY-----\nMIIE...",
    "Version": 1,
    "LastModifiedDate": "2026-01-23T..."
  }
}
```

---

### 手順3: terraform.tfvarsを設定

ファイル: `Lambda/GenerateSignedURL/terraform.tfvars`

```terraform
region                 = "ap-northeast-1"
profile                = "AdministratorAccess-339126664118"
cloudfront_domain      = "d2zaynqig5sahs.cloudfront.net"
cloudfront_key_pair_id = "APKAXXXXXXXXXX"  # ← 手順1で取得

tags = {
  Project     = "Grandma-Alert"
  Environment = "production"
  ManagedBy   = "Terraform"
}
```

---

### 手順4: Lambda関数をデプロイ

```bash
cd /Users/sksrdik/workspace/Project/Grandma_Alert/Lambda/GenerateSignedURL

# 初期化
terraform init

# プラン確認
terraform plan

# デプロイ
terraform apply

# 出力確認
terraform output
```

**期待される出力:**

```
lambda_function_name = "GenerateSignedURL"
lambda_function_url  = "https://xyz123.lambda-url.ap-northeast-1.on.aws/"
```

---

### 手順5: CloudFront署名検証を有効化

⚠️ **現在のCloudFront設定では署名検証が無効**

#### オプションA: Key Groupを使用（推奨）

`S3/Dashboard/cloudfront.tf` に追加:

```terraform
# CloudFront Public Key
resource "aws_cloudfront_public_key" "signed_url_key" {
  name        = "grandma-alert-signed-url-key"
  comment     = "Public key for signed URL verification"
  encoded_key = file("${path.module}/cloudfront_public_key.pem")
}

# CloudFront Key Group
resource "aws_cloudfront_key_group" "signed_url" {
  name    = "grandma-alert-key-group"
  comment = "Key group for signed URL verification"
  items   = [aws_cloudfront_public_key.signed_url_key.id]
}

# CloudFront Distributionに追加
resource "aws_cloudfront_distribution" "dashboard" {
  # ... 既存の設定 ...

  # 署名検証を有効化
  trusted_key_groups = [aws_cloudfront_key_group.signed_url.id]
}
```

**公開鍵の取得方法:**

```bash
# 秘密鍵から公開鍵を抽出
openssl rsa -pubout -in ~/secrets/grandma-alert/pk-APKAXXXXXXXXXX.pem \
  -out /Users/sksrdik/workspace/Project/Grandma_Alert/S3/Dashboard/cloudfront_public_key.pem
```

#### オプションB: Key Pair IDを直接指定

```terraform
resource "aws_cloudfront_distribution" "dashboard" {
  # ... 既存の設定 ...

  # アカウント自身のKey Pairを信頼
  trusted_signers = ["self"]
}
```

**再デプロイ:**

```bash
cd /Users/sksrdik/workspace/Project/Grandma_Alert/S3/Dashboard
terraform apply
```

---

### 手順6: 動作確認

#### テスト1: 署名付きURL生成

```bash
# Lambda Function URLを取得
LAMBDA_URL=$(cd Lambda/GenerateSignedURL && terraform output -raw lambda_function_url)

# 署名付きURLを生成
curl -X POST "$LAMBDA_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/index.html",
    "expiration_minutes": 10
  }' | jq
```

**期待される結果:**

```json
{
  "signed_url": "https://d2zaynqig5sahs.cloudfront.net/index.html?Expires=...&Signature=...&Key-Pair-Id=APKA...",
  "expires_at": "2026-01-23T10:30:00",
  "expires_in_minutes": 10
}
```

#### テスト2: 署名なしURLの拒否確認

```bash
# 署名なしでアクセス（403エラーになるべき）
curl -I https://d2zaynqig5sahs.cloudfront.net/index.html
```

**期待される結果:**

```
HTTP/2 403
```

#### テスト3: 署名付きURLでのアクセス成功

```bash
# 生成された署名付きURLでアクセス（成功するべき）
SIGNED_URL="<テスト1で取得したsigned_url>"
curl -I "$SIGNED_URL"
```

**期待される結果:**

```
HTTP/2 200
content-type: text/html
```

---

## 🚨 重大な問題（即座に対応が必要）

### 1. 依存ライブラリのデプロイ修正

- [ ] Lambda Layerの作成
- [ ] `requirements.txt` の依存関係をインストール
- [ ] cryptography, boto3 のパッケージング
- **影響:** 現在、Lambda実行時に `ModuleNotFoundError` が発生する可能性
- **優先度:** 🔴 高
- **関連:** [Issues.md](Issues.md#問題7-デプロイメントプロセスの改善余地) - Lambda/GenerateSignedURL - 問題7

---

## ⚠️ セキュリティ関連（本番環境前に対応）

### 2. Lambda Function URLの認証追加

- [ ] IAM認証の実装
- [ ] または API Gateway + APIキーの実装
- [ ] Cognito Identity Pool の設定（IAM認証の場合）
- **現状:** `authorization_type = "NONE"` で誰でもアクセス可能
- **優先度:** 🔴 高
- **関連:** [Issues.md](Issues.md#問題1-lambda-function-urlが認証なし) - Lambda/GenerateSignedURL - 問題1

### 3. レート制限の実装

- [ ] API Gatewayによるレート制限設定
- [ ] または Lambda内でのレート制限ロジック
- [ ] Redis/ElastiCacheの検討（高度な制限が必要な場合）
- **現状:** レート制限なし、DoS攻撃のリスク
- **優先度:** 🔴 高
- **関連:** [Issues.md](Issues.md#問題3-レート制限がない) - Lambda/GenerateSignedURL - 問題3

### 4. CORS設定の厳格化

- [ ] `allowed_origins` を特定のドメインに制限
- **現状:** `allowed_origins = ["*"]` で全ドメインを許可
- **優先度:** 🟡 中
- **関連:** [Issues.md](Issues.md#問題2-cors設定が過度に緩い-1) - Lambda/GenerateSignedURL - 問題2

---

## 🔧 改善提案（品質向上）

### 5. エラーハンドリングの改善

- [ ] カスタム例外クラスの追加
- [ ] バリデーションエラーの適切な処理（400エラー）
- [ ] 詳細なエラーメッセージの提供
- **優先度:** 🟡 中
- **関連:** [Issues.md](Issues.md#問題5-エラーハンドリングの不足) - Lambda/GenerateSignedURL - 問題5

### 6. ロギングの強化

- [ ] 構造化ロギングの実装
- [ ] リクエスト情報の記録
- [ ] CloudWatch Logs Insightsクエリの作成
- **優先度:** 🟡 中
- **関連:** [Issues.md](Issues.md#問題6-ロギングの不足) - Lambda/GenerateSignedURL - 問題6

### 7. CloudFront Key Groupへの移行

- [ ] Key Pairから Key Groupへの移行
- [ ] 公開鍵をTerraformで管理
- [ ] キーローテーション手順の整備
- **優先度:** 🟡 中
- **関連:** [Issues.md](Issues.md#問題4-cloudfront-key-pairの管理が手動) - Lambda/GenerateSignedURL - 問題4

---

## 🚀 パフォーマンス関連

### 8. コールドスタート対策

- [ ] プロビジョニング済み同時実行数の設定
- [ ] または ElastiCache Redisでのキャッシュ戦略
- [ ] メモリ割り当ての最適化
- **優先度:** 🟢 低
- **関連:** [Issues.md](Issues.md#問題8-コールドスタートの遅延) - Lambda/GenerateSignedURL - 問題8

---

## 📋 未実装機能

### 9. モニタリング・アラート機能の追加

- [ ] CloudWatch アラームの設定
- [ ] エラー率の監視
- [ ] レスポンス時間の追跡
- [ ] ダッシュボードの作成
- **優先度:** 🟡 中
- **関連:** [Issues.md](Issues.md#問題10-モニタリングアラート機能の不足) - Lambda/GenerateSignedURL - 問題10

### 10. テストコードの追加

- [ ] ユニットテストの実装（pytest）
- [ ] 統合テストの実装
- [ ] CI/CDパイプラインの構築
- **優先度:** 🟡 中
- **関連:** [Issues.md](Issues.md#問題11-テストコードの不足) - Lambda/GenerateSignedURL - 問題11

---

## ✅ Lambda/GenerateSignedURL - 良好な実装（維持）

- ✓ Lambda Function URLの基本設定が適切
- ✓ 環境変数での設定管理
- ✓ SSMパラメータストアでの秘密鍵管理
- ✓ IAMロールの適切な権限設定
- ✓ CloudFront署名アルゴリズムの正しい実装

---

## トラブルシューティング

### エラー1: SSMパラメータが見つからない

```
ParameterNotFound: Parameter /cloudfront/private-key not found
```

**原因:** SSMに秘密鍵が保存されていない  
**解決:** 手順2を実行

---

### エラー2: Lambda実行エラー

```
ModuleNotFoundError: No module named 'cryptography'
```

**原因:** 依存ライブラリが含まれていない  
**解決:**

```bash
cd Lambda/GenerateSignedURL
rm -rf package lambda_function.zip
terraform apply
```

---

### エラー3: CloudFront 403エラー（署名検証失敗）

```
MissingKey: The specified key does not exist
```

**原因1:** CloudFrontに署名検証設定がない  
**解決:** 手順5を実行

**原因2:** Key Pair IDが誤っている  
**解決:** terraform.tfvarsを確認

---

## 完了チェックリスト

デプロイ完了後、以下を確認してください：

- [ ] Lambda Function URLが生成されている
- [ ] SSMパラメータストアに秘密鍵が保存されている
- [ ] CloudFrontで署名検証が有効になっている
- [ ] 署名付きURLでアクセスできる
- [ ] 署名なしURLがブロックされる（403エラー）
- [ ] 有効期限切れURLがブロックされる（403エラー）

---

# 全体的な実装順序

## 🎯 推奨実装順序

### フェーズ1: 基礎機能の完成（即座に対応）

#### S3/Dashboard:

1. ✅ **HTMLファイルの基本実装**（問題1）- 完了

#### Lambda/GenerateSignedURL:

2. ✅ **依存ライブラリのデプロイ修正**（問題1）- 完了
3. ✅ **CloudFront Key Pair作成とSSM保存**（手順1-2）- 完了
4. ✅ **Lambda関数デプロイ**（手順3-4）- 完了
5. ⬜ **CloudFront署名検証設定**（手順5）
6. ⬜ **動作確認・テスト**（手順6）

#### Secrets Manager:

7. ✅ **シークレット作成（LineRichMenu）** - 完了
8. ✅ **通報情報の格納（名前、住所、病歴）** - 完了
9. ✅ **Lambda関数からのアクセス許可設定** - 完了

#### ダッシュボード ↔ S3/Images 連携:

10. ⬜ **署名付きURL方式への移行**（ダッシュボード連携 - 問題1）
    - `CONFIG.LAMBDA_SIGNED_URL_ENDPOINT` を設定
    - `loadCameraImage()` 関数を修正
11. ⬜ **カメラリスト取得APIの実装**（ダッシュボード連携 - 問題2）
    - Lambda関数 `ListCameras` を作成
    - `loadCamerasFromS3()` 関数を実装

### フェーズ2: セキュリティ強化（本番環境前に対応）

#### S3/Images:

9. ⬜ **パブリックアクセスの無効化**（S3/Images - 問題1） 🔴 最優先
   - `block_public_acls` 等を `true` に変更
   - パブリックポリシーを削除

#### 共通:

10. ⬜ **Lambda Function URLの認証追加**（Lambda - 問題2）
11. ⬜ **レート制限の実装**（Lambda - 問題3）
12. ⬜ **CORS設定の厳格化**（S3/Dashboard, S3/Images, Lambda）

#### S3/Dashboard:

13. ⬜ **アクセスログの設定**（S3 - 問題3）

### フェーズ3: 品質向上（1ヶ月以内）

#### ダッシュボード連携:

14. ⬜ **画像パス規則の文書化と標準化**（ダッシュボード連携 - 問題3）
15. ⬜ **エラーハンドリングの改善**（ダッシュボード連携 - 問題4）

#### S3/Dashboard:

16. ⬜ **バリデーション機能の追加**（S3 - 問題4）
17. ⬜ **タグ管理の統一**（S3 - 問題5）
18. ⬜ **エラーハンドリングの強化**（S3 - 問題6）
19. ⬜ **キャッシュ戦略の最適化**（S3 - 問題7）

#### Lambda/GenerateSignedURL:

20. ⬜ **エラーハンドリングの改善**（Lambda - 問題5）
21. ⬜ **ロギングの強化**（Lambda - 問題6）
22. ⬜ **CloudFront Key Groupへの移行**（Lambda - 問題7）
23. ⬜ **コールドスタート対策**（Lambda - 問題8）

#### 共通:

24. ⬜ **モニタリング機能の追加**（S3 - 問題10、Lambda - 問題9）
25. ⬜ **テストコードの追加**（Lambda - 問題10）

---

## 📊 優先度サマリー

| 優先度  | タスク数 | モジュール                                                                                   |
| ------- | -------- | -------------------------------------------------------------------------------------------- |
| 🔴 高   | 4        | S3/Images パブリックアクセス無効化、署名付きURL移行、カメラリストAPI、Lambda認証、レート制限 |
| 🟡 中   | 12       | CORS、ログ、エラーハンドリング、Key Group移行、監視、パス規則文書化                          |
| 🟢 低   | 7        | バリデーション、タグ、キャッシュ最適化、テストコード等                                       |
| ✅ 完了 | 7        | HTML実装、Lambda署名URL、Secrets Manager設定                                                 |

---

## 📚 参考情報

- **問題点一覧:** [Issues.md](Issues.md)
- **設計書:** [Design.md](Design.md)
- **要件定義:** プロジェクトルートの README 参照
- **セキュリティベストプラクティス:** AWS Well-Architected Framework
- **CloudFront署名付きURL:** [AWS Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-urls.html)

---

## AWSリソース情報

```bash
# S3バケット
dashboard_bucket_name = "grandma-alert-dashboard-bucket-339126664118"

# CloudFront
cloudfront_domain_name = "d2zaynqig5sahs.cloudfront.net"
cloudfront_distribution_id = "E1P9VKFGHOPFL"

# Lambda（デプロイ後）
lambda_function_name = "GenerateSignedURL"
lambda_function_url = "https://[ID].lambda-url.ap-northeast-1.on.aws/"
```
