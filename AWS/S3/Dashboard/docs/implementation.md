# Dashboard S3リソースの実装内容と特徴

**作成日:** 2026年1月23日  
**対象モジュール:** `S3/Dashboard`

---

## 概要

Grandma Alertプロジェクトにおける、ダッシュボード用の静的Webサイトホスティング環境を提供するTerraformモジュールです。S3バケットとCloudFrontを組み合わせて、セキュアな画像閲覧ダッシュボードを実現します。

---

## リソース構成

### 1. S3バケット

#### 1.1 メインバケット (`aws_s3_bucket.dashboard`)

- **目的:** ダッシュボードのHTMLファイルを格納
- **命名:** `var.dashboard_bucket_name` で指定（グローバル一意）
- **タグ管理:** プロジェクト共通タグを適用

#### 1.2 バージョニング (`aws_s3_bucket_versioning.dashboard`)

- **設定:** `Enabled`
- **効果:** ファイルの変更履歴を保持し、誤った更新からの復元を可能にする

#### 1.3 パブリックアクセスブロック (`aws_s3_bucket_public_access_block.dashboard`)

```terraform
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true
```

- **セキュリティ方針:** バケット自体はプライベート化
- **アクセス方法:** CloudFront経由のみアクセス可能

#### 1.4 静的Webサイトホスティング (`aws_s3_bucket_website_configuration.dashboard`)

- **インデックスドキュメント:** `index.html`
- **エラードキュメント:** `error.html`
- **注意:** S3のWebサイトエンドポイントは使用せず、CloudFront経由でアクセス

#### 1.5 CORS設定 (`aws_s3_bucket_cors_configuration.dashboard`)

```terraform
allowed_headers = ["*"]
allowed_methods = ["GET", "HEAD"]
allowed_origins = ["*"]
expose_headers  = ["ETag"]
max_age_seconds = 3000
```

- **許可メソッド:** GET, HEAD（読み取り専用）
- **オリジン:** 現在は全ドメイン許可（将来的に制限推奨）

### 2. CloudFront Distribution

#### 2.1 Origin Access Control (OAC) (`aws_cloudfront_origin_access_control.dashboard`)

- **タイプ:** S3用OAC
- **署名動作:** `always`（すべてのリクエストに署名）
- **署名プロトコル:** `sigv4`（AWS Signature Version 4）
- **目的:** CloudFrontのみがS3バケットにアクセス可能にする

#### 2.2 ディストリビューション設定 (`aws_cloudfront_distribution.dashboard`)

**基本設定:**

- **IPv6対応:** 有効
- **デフォルトルートオブジェクト:** `index.html`
- **オリジン:** S3バケットの `bucket_regional_domain_name` を使用

**キャッシュ動作:**

```terraform
min_ttl     = 0
default_ttl = 5  # 5秒
max_ttl     = 5
```

- **TTL設定:** 5秒（画像の5秒ごとのリフレッシュに対応）
- **圧縮:** 有効
- **HTTPS:** `redirect-to-https`（HTTP→HTTPS自動リダイレクト）

**エラーハンドリング:**

- **403エラー:** `/error.html` にリダイレクト
- **404エラー:** `/error.html` にリダイレクト

#### 2.3 S3バケットポリシー (`aws_s3_bucket_policy.dashboard_cloudfront`)

```json
{
  "Principal": {
    "Service": "cloudfront.amazonaws.com"
  },
  "Action": "s3:GetObject",
  "Condition": {
    "StringEquals": {
      "AWS:SourceArn": "<CloudFront Distribution ARN>"
    }
  }
}
```

- **許可対象:** CloudFrontサービスプリンシパル
- **条件:** 特定のCloudFront DistributionのARNと一致する場合のみ
- **効果:** S3バケットへの直接アクセスを完全にブロック

### 3. HTMLファイル

#### 3.1 インデックスページ (`aws_s3_object.index_html`)

- **ソース:** `upload_file/index.html`
- **Content-Type:** `text/html`
- **更新検知:** `filemd5()` でETagを計算し、変更時のみ再アップロード

#### 3.2 エラーページ (`aws_s3_object.error_html`)

- **ソース:** `upload_file/error.html`
- **Content-Type:** `text/html`
- **目的:** 403/404エラー時の表示

---

## 主要な特徴

### 🔒 セキュリティ

1. **プライベートバケット**: パブリックアクセスを完全にブロック
2. **CloudFront経由のみアクセス**: OACによる厳格な制御
3. **HTTPS強制**: すべてのアクセスをHTTPSにリダイレクト
4. **署名付きURL対応**: 将来的な実装予定（現在は未実装）

### ⚡ パフォーマンス

1. **低TTL設定**: 5秒でキャッシュ更新（最新画像を素早く反映）
2. **圧縮有効**: コンテンツ圧縮によるデータ転送量削減
3. **グローバル配信**: CloudFrontのエッジロケーション活用

### 🛠️ 運用性

1. **バージョニング**: ファイル変更履歴の保持
2. **ETag管理**: ファイル内容に基づく変更検知
3. **依存関係管理**: `depends_on` で明示的な順序制御

---

## 変数定義

| 変数名                  | 型            | 説明                             | 必須 |
| ----------------------- | ------------- | -------------------------------- | ---- |
| `region`                | `string`      | AWSリージョン                    | ✅   |
| `profile`               | `string`      | AWS認証プロファイル              | ✅   |
| `dashboard_bucket_name` | `string`      | S3バケット名（グローバルで一意） | ✅   |
| `tags`                  | `map(string)` | リソースに付与するタグ           | ❌   |

**デフォルトタグ:**

```terraform
tags = {
  Project   = "Grandma-Alert"
  ManagedBy = "Terraform"
}
```

---

## 出力値

| 出力名                        | 説明                                   |
| ----------------------------- | -------------------------------------- |
| `dashboard_bucket_name`       | S3バケット名                           |
| `dashboard_bucket_arn`        | S3バケットARN                          |
| `dashboard_website_url`       | S3 Website URL（非推奨）               |
| `cloudfront_distribution_id`  | CloudFront Distribution ID             |
| `cloudfront_domain_name`      | CloudFront ドメイン名（アクセス用URL） |
| `cloudfront_distribution_arn` | CloudFront Distribution ARN            |

**推奨アクセス方法:**  
`https://<cloudfront_domain_name>` を使用（S3 Website URLは使用しない）

---

## アーキテクチャ図

```
[ユーザー]
    |
    | HTTPS
    ↓
[CloudFront Distribution]
    |
    | OAC (Origin Access Control)
    ↓
[S3 Bucket (Private)]
    ├── index.html
    └── error.html
```

---

## 技術的な工夫

### 1. Origin Access Control (OAC) の採用

- **旧方式:** Origin Access Identity (OAI)
- **新方式:** Origin Access Control (OAC)
- **メリット:**
  - AWS Signature Version 4 のサポート
  - より強固なセキュリティ
  - AWSの推奨方式

### 2. 低TTLキャッシュ戦略

```terraform
default_ttl = 5
```

- **理由:** ダッシュボードは5秒ごとに画像をリフレッシュする仕様
- **トレードオフ:** CloudFrontの効果は限定的だが、S3直接アクセスより高速
- **将来的な改善:** 画像URLにタイムスタンプを付与してキャッシュバスティング

### 3. ETag ベースの変更検知

```terraform
etag = filemd5("${path.module}/upload_file/index.html")
```

- **効果:** ファイル内容が変わった場合のみS3にアップロード
- **メリット:** 不要なアップロードを防ぎ、デプロイ時間を短縮

---

## 関連ドキュメント

- **使い方:** [usage.md](usage.md)
- **現状の問題点:** [issues.md](issues.md)
- **TODO:** [../../../docs/TODO.md](../../../docs/TODO.md)
- **設計書:** [../../../docs/Design.md](../../../docs/Design.md)
