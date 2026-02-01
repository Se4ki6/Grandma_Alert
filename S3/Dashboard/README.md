# S3 Dashboard Bucket

静的Webサイトホスティング用のパブリックS3バケットを管理します。

## リソース

- **aws_s3_bucket.dashboard** - ダッシュボード用バケット
- **aws_s3_bucket_versioning.dashboard** - バージョニング設定
- **aws_s3_bucket_public_access_block.dashboard** - パブリックアクセス設定
- **aws_s3_bucket_policy.dashboard_public** - バケットポリシー（公開読み取り）
- **aws_s3_bucket_website_configuration.dashboard** - 静的Webサイト設定
- **aws_s3_bucket_cors_configuration.dashboard** - CORS設定
- **aws_s3_object.index_html** - index.htmlファイル
- **aws_s3_object.error_html** - error.htmlファイル

## 使用方法

```bash
cd S3/Dashboard
terraform init
terraform plan
terraform apply
```

## 変数

| 変数名                | 説明                | デフォルト値 |
| --------------------- | ------------------- | ------------ |
| region                | AWSリージョン       | -            |
| profile               | AWS認証プロファイル | -            |
| dashboard_bucket_name | バケット名          | -            |

## 出力

| 出力名                | 説明         |
| --------------------- | ------------ |
| dashboard_bucket_name | バケット名   |
| dashboard_bucket_arn  | バケットARN  |
| dashboard_website_url | WebサイトURL |
