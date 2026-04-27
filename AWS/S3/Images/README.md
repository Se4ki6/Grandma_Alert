# S3 Images Bucket

画像アップロード用のプライベートS3バケットを管理します。
S3に画像がアップロードされると、自動的にLambda関数（LINE通知）がトリガーされます。

## リソース

- **aws_s3_bucket.images** - 画像保存用バケット
- **aws_s3_bucket_versioning.images** - バージョニング設定
- **aws_s3_bucket_server_side_encryption_configuration.images** - サーバーサイド暗号化
- **aws_s3_bucket_lifecycle_configuration.images_expire** - ライフサイクルルール（自動削除）
- **aws_s3_bucket_notification.images_upload_trigger** - Lambda関数トリガー設定
- **aws_lambda_permission.allow_s3_invoke** - S3がLambdaを実行する権限

## 使用方法

```bash
cd S3/Images
terraform init
terraform plan
terraform apply
```

## 機能詳細

### Lambda関数トリガー

以下の画像形式がS3にアップロードされると、LINE通知用Lambda関数が自動的に実行されます：
- `.jpg` / `.jpeg`
- `.png`

Lambda関数は以下の処理を実行できます：
1. S3からアップロードされた画像を読み取り
2. LINE Bot APIを使用してユーザーに通知を送信
