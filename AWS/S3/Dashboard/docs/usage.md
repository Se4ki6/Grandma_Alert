# Dashboard S3リソースの使い方

**作成日:** 2026年1月23日  
**対象モジュール:** `S3/Dashboard`

---

## 前提条件

### 必要なツール

- Terraform >= 1.0
- AWS CLI（認証設定済み）
- 適切なIAM権限

### 必要なIAM権限

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:PutBucketPolicy",
        "s3:PutBucketVersioning",
        "s3:PutBucketWebsite",
        "s3:PutBucketCORS",
        "s3:PutObject",
        "s3:DeleteObject",
        "cloudfront:CreateDistribution",
        "cloudfront:UpdateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:CreateOriginAccessControl",
        "cloudfront:DeleteOriginAccessControl"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 初期セットアップ

### 1. terraform.tfvars の設定

`S3/Dashboard/terraform.tfvars` を作成・編集:

```terraform
region                = "ap-northeast-1"
profile               = "your-aws-profile"
dashboard_bucket_name = "grandma-alert-dashboard-unique-name"

tags = {
  Project     = "Grandma-Alert"
  Environment = "production"
  ManagedBy   = "Terraform"
}
```

**重要:** `dashboard_bucket_name` はAWS全体で一意である必要があります。

### 2. HTMLファイルの準備

`upload_file/` ディレクトリにHTMLファイルを配置:

```bash
cd S3/Dashboard/upload_file
```

**index.html:**

- ダッシュボードのメインページ
- カメラ画像のグリッド表示
- 5秒ごとの自動リフレッシュ機能

**error.html:**

- エラーページ（403/404）
- ユーザーフレンドリーなエラーメッセージ

---

## デプロイ手順

### 初回デプロイ

```bash
# ディレクトリに移動
cd /path/to/Grandma_Alert/S3/Dashboard

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
cloudfront_domain_name = "d1234567890abc.cloudfront.net"
cloudfront_distribution_id = "E1ABCDEFGHIJK"
dashboard_bucket_name = "grandma-alert-dashboard-unique-name"
```

**ダッシュボードURL:**

```
https://d1234567890abc.cloudfront.net
```

---

## HTMLファイルの更新

### 手順

1. **ファイルを編集:**

   ```bash
   vim upload_file/index.html
   # または
   vim upload_file/error.html
   ```

2. **変更を適用:**

   ```bash
   terraform apply
   ```

   - Terraformが自動的に `filemd5()` で変更を検知
   - 変更されたファイルのみS3にアップロード

3. **キャッシュのクリア（必要な場合）:**
   ```bash
   aws cloudfront create-invalidation \
     --distribution-id E1ABCDEFGHIJK \
     --paths "/*"
   ```

   - TTLが5秒なので、通常は不要
   - 即座に反映させたい場合のみ実行

---

## 動作確認

### 1. CloudFront経由のアクセス

```bash
# CloudFront URLにアクセス
curl -I https://d1234567890abc.cloudfront.net
```

**期待する結果:**

```
HTTP/2 200
content-type: text/html
x-cache: Hit from cloudfront
```

### 2. S3直接アクセスの拒否確認

```bash
# S3バケットに直接アクセス（拒否されるべき）
curl -I https://grandma-alert-dashboard-unique-name.s3.amazonaws.com/index.html
```

**期待する結果:**

```
HTTP/1.1 403 Forbidden
```

### 3. エラーページの確認

```bash
# 存在しないページにアクセス
curl https://d1234567890abc.cloudfront.net/nonexistent.html
```

**期待する結果:** `error.html` の内容が返される

---

## トラブルシューティング

### 問題1: CloudFrontのキャッシュが更新されない

**原因:** TTLが5秒だが、まだキャッシュが残っている

**解決策:**

```bash
# キャッシュを強制削除
aws cloudfront create-invalidation \
  --distribution-id E1ABCDEFGHIJK \
  --paths "/*"

# 無効化の進行状況を確認
aws cloudfront get-invalidation \
  --distribution-id E1ABCDEFGHIJK \
  --id <invalidation-id>
```

### 問題2: HTMLファイルが更新されない

**原因:** ファイルの `etag` が変わっていない

**解決策:**

```bash
# ファイルが実際に変更されているか確認
md5 upload_file/index.html

# 強制的に再アップロード
terraform taint aws_s3_object.index_html
terraform apply
```

### 問題3: S3バケット名の衝突

**エラーメッセージ:**

```
Error: Error creating S3 bucket: BucketAlreadyExists
```

**解決策:**

```terraform
# terraform.tfvars を編集
dashboard_bucket_name = "grandma-alert-dashboard-unique-name-v2"
```

### 問題4: 403 Forbidden エラー

**原因1:** CloudFrontのOACが正しく設定されていない

**解決策:**

```bash
# バケットポリシーを確認
aws s3api get-bucket-policy --bucket <bucket-name>

# 必要に応じて再適用
terraform destroy -target=aws_s3_bucket_policy.dashboard_cloudfront
terraform apply
```

**原因2:** パブリックアクセスブロックの設定ミス

**解決策:**

```bash
# パブリックアクセスブロック設定を確認
aws s3api get-public-access-block --bucket <bucket-name>
```

---

## 日常的な運用

### ダッシュボードへのアクセス

**ユーザー向けURL:**

```
https://<cloudfront_domain_name>
```

**注意事項:**

- 現在は誰でもアクセス可能
- 将来的に署名付きURL方式を実装予定

### ログの確認

#### CloudFrontのアクセスログ

```bash
# CloudFrontのログを有効化（オプション）
# ログバケットを別途作成する必要があります
```

#### S3アクセスログ

```bash
# S3のアクセスログを有効化（オプション）
# ログバケットを別途作成する必要があります
```

### モニタリング

#### CloudWatch メトリクス

```bash
# CloudFrontのリクエスト数を確認
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=E1ABCDEFGHIJK \
  --start-time 2026-01-23T00:00:00Z \
  --end-time 2026-01-23T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

---

## リソースの削除

### 注意事項

- S3バケットは空にしてから削除される
- CloudFrontの削除には5-10分程度かかる場合がある

### 削除手順

```bash
# すべてのリソースを削除
terraform destroy

# 確認プロンプトで yes を入力
```

**または、特定のリソースのみ削除:**

```bash
# CloudFrontのみ削除
terraform destroy -target=aws_cloudfront_distribution.dashboard

# S3バケットのみ削除
terraform destroy -target=aws_s3_bucket.dashboard
```

---

## ベストプラクティス

### 1. HTMLファイルのバージョン管理

```bash
# Gitでバージョン管理
git add upload_file/index.html
git commit -m "Update dashboard UI"
```

### 2. 変更前のバックアップ

```bash
# 重要な変更前はバックアップを作成
terraform state pull > backup.tfstate
```

### 3. 段階的なデプロイ

```bash
# 開発環境で先にテスト
terraform workspace new dev
terraform apply

# 動作確認後に本番環境へ
terraform workspace select default
terraform apply
```

### 4. コスト最適化

- CloudFrontのデータ転送量を定期的に確認
- 不要なキャッシュ無効化を避ける（5秒TTLなので通常は不要）
- S3のバージョニングで古いバージョンを定期的に削除

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

# リソースの詳細
terraform state show aws_s3_bucket.dashboard
```

### AWS CLI

```bash
# バケット一覧
aws s3 ls

# バケット内容確認
aws s3 ls s3://<bucket-name>

# CloudFrontディストリビューション一覧
aws cloudfront list-distributions

# キャッシュ無効化
aws cloudfront create-invalidation \
  --distribution-id <dist-id> \
  --paths "/*"
```

---

## 次のステップ

1. **署名付きURLの実装** → [TODO.md](../../../docs/TODO.md) のタスク2.3参照
2. **ダッシュボードUI の実装** → `upload_file/index.html` の開発
3. **セキュリティ強化** → CORS設定の厳格化

---

## サポート

質問や問題がある場合:

- [GitHub Issues](https://github.com/your-repo/issues)
- プロジェクトドキュメント: [docs/](../../../docs/)
