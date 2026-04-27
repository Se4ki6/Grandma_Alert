# セキュリティ強化の実装完了

## 実装内容

### ✅ 2.1 S3バケットをプライベート化

[AWS/S3/Dashboard/s3.tf](AWS/S3/Dashboard/s3.tf)を変更：

- パブリックアクセスブロックを有効化
- パブリックバケットポリシーを削除
- CloudFront経由のみアクセス可能に変更

### ✅ 2.2 CloudFrontディストリビューションの作成

[AWS/S3/Dashboard/cloudfront.tf](AWS/S3/Dashboard/cloudfront.tf)を作成：

- Origin Access Control (OAC)を設定
- S3へのアクセスをCloudFrontのみに制限
- キャッシュTTLを5秒に設定（画像の即時更新）
- カスタムエラーページ設定（403/404）

### ✅ 2.3 Lambda関数で署名付きURL生成

[AWS/Lambda/GenerateSignedURL/](AWS/Lambda/GenerateSignedURL/)を作成：

- CloudFront署名付きURLを生成するLambda関数
- SSMパラメータストアから秘密鍵を安全に取得
- Lambda Function URLでHTTPSエンドポイント提供
- 有効期限付きアクセス制御（デフォルト60分）

## デプロイ手順

### 1. S3 + CloudFrontのデプロイ

```bash
cd AWS/S3/Dashboard
terraform init
terraform plan
terraform apply
```

デプロイ後、CloudFrontのドメイン名を確認：

```bash
terraform output cloudfront_domain_name
```

### 2. CloudFront Key Pairの作成

**重要**: この作業はルートユーザーのみ実行可能です

1. AWSマネジメントコンソールにルートユーザーでログイン
2. 右上のアカウント名 → **セキュリティ認証情報**
3. **CloudFront キーペア** → **新しいキーペアを作成**
4. 秘密鍵（.pemファイル）をダウンロード
5. Key Pair IDをメモ（例: `APKAXXXXXXXXXX`）

### 3. 秘密鍵をSSMに保存

```bash
aws ssm put-parameter \
  --name "/cloudfront/private-key" \
  --type "SecureString" \
  --value file://pk-APKAXXXXXXXXXX.pem \
  --region ap-northeast-1 \
  --profile default
```

### 4. Lambda関数のデプロイ

[AWS/Lambda/GenerateSignedURL/terraform.tfvars](AWS/Lambda/GenerateSignedURL/terraform.tfvars)を編集：

```terraform
cloudfront_domain      = "d1234567890abc.cloudfront.net"  # 手順1で取得
cloudfront_key_pair_id = "APKAXXXXXXXXXX"                 # 手順2で取得
```

デプロイ：

```bash
cd AWS/Lambda/GenerateSignedURL
terraform init
terraform plan
terraform apply
```

### 5. 動作確認

Lambda Function URLを取得：

```bash
terraform output lambda_function_url
```

署名付きURL生成テスト：

```bash
curl -X POST https://<lambda-function-url> \
  -H "Content-Type: application/json" \
  -d '{"path": "/index.html", "expiration_minutes": 10}'
```

## 次のステップ

以下のタスクが残っています：

### 📋 2.4 通知システムの修正

- [ ] `NotifyFamily` Lambda関数を修正
- [ ] 画像URLを署名付きURLに変更

### 📋 2.5 Dashboard アクセスの署名付きURL化

- [ ] API Gateway + Lambda でダッシュボード用エンドポイント作成
- [ ] LINEリッチメニューに「ダッシュボードを開く」ボタン追加

### 📋 2.6 テスト

- [ ] 署名なしアクセスが拒否されることを確認
- [ ] 署名付きURLでアクセス成功を確認
- [ ] URL有効期限切れ後のアクセス拒否を確認

## セキュリティ注意事項

### 現在の状態

- ✅ S3バケットは完全プライベート
- ✅ CloudFront経由のみアクセス可能
- ⚠️ Lambda Function URLは認証なし（開発用）

### 本番環境への推奨改善

1. Lambda Function URLをAPI Gateway + 認証に置き換え
2. CORS設定を特定ドメインに制限
3. CloudWatch Alarmsでエラー監視

## 参考情報

- [CloudFront OAC設定ガイド](https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [署名付きURL作成方法](https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-urls.html)
- 詳細: [AWS/Lambda/GenerateSignedURL/README.md](AWS/Lambda/GenerateSignedURL/README.md)
