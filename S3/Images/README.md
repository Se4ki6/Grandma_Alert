# S3 Images Bucket

画像アップロード用のプライベートS3バケットを管理します。

## リソース

- **aws_s3_bucket.images** - 画像保存用バケット
- **aws_s3_bucket_versioning.images** - バージョニング設定
- **aws_s3_bucket_server_side_encryption_configuration.images** - サーバーサイド暗号化
- **aws_s3_bucket_lifecycle_configuration.images_expire** - ライフサイクルルール（自動削除）

## 使用方法

```bash
cd S3/Images
terraform init
terraform plan
terraform apply
```

## 変数

| 変数名                    | 説明                     | デフォルト値 |
| ------------------------- | ------------------------ | ------------ |
| region                    | AWSリージョン            | -            |
| profile                   | AWS認証プロファイル      | -            |
| images_bucket_name        | バケット名               | -            |
| lifecycle_expiration_days | 画像の自動削除までの日数 | 1            |

## 出力

| 出力名             | 説明        |
| ------------------ | ----------- |
| images_bucket_name | バケット名  |
| images_bucket_arn  | バケットARN |
