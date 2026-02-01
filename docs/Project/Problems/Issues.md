# Grandma Alert プロジェクト - 現状の問題点

**最終更新:** 2026年1月23日  
**管理対象モジュール:** 全モジュール

---

## 📋 目次

1. [S3/Dashboard モジュール](#s3dashboard-モジュール)
2. [Lambda/GenerateSignedURL モジュール](#lambdageneratesignedurl-モジュール)

---

# S3/Dashboard モジュール

**作成日:** 2026年1月23日  
**対象モジュール:** `S3/Dashboard`

## ⚠️ セキュリティ関連（本番環境前に対応）

### ⚠️ 問題2: CORS設定が過度に緩い

**現状:**

```terraform
allowed_origins = ["*"]  # すべてのドメインを許可
```

**影響:**

- クロスサイトスクリプティング（XSS）のリスク
- 意図しないドメインからのアクセスを許可
- セキュリティベストプラクティスに反する

**セキュリティリスク:** 🟡 中

**推奨対応:**

```terraform
# 特定のドメインのみ許可
allowed_origins = [
  "https://<your-domain>.com",
  "https://d1234567890abc.cloudfront.net"  # CloudFront自身
]
```

**注意事項:**

- 署名付きURL方式では、CORSの制限がより重要
- 将来的に独自ドメインを使用する場合は更新が必要

**関連タスク:** [TODO.md](TODO.md) - S3/Dashboard - 問題3

---

### 📊 問題3: アクセスログが未設定

**現状:**

- CloudFrontのアクセスログが無効
- S3のアクセスログも無効

**影響:**

- アクセスパターンの把握ができない
- セキュリティインシデントの調査が困難
- 監査証跡がない

**セキュリティリスク:** 🟡 中

**推奨対応:**

#### CloudFrontログの有効化:

```terraform
resource "aws_cloudfront_distribution" "dashboard" {
  # 既存の設定...

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront/"
  }
}
```

#### S3アクセスログの有効化:

```terraform
resource "aws_s3_bucket_logging" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "s3-access-logs/"
}
```

**コスト影響:** 月間数百円〜（アクセス量による）

---

## 🔧 改善提案（品質向上）

### 💡 問題4: バリデーション機能の不足

**現状:**

- 空ファイルがデプロイされる可能性がある
- ファイルの存在確認が不十分

**影響:**

- デプロイ後に問題を発見
- ロールバックの手間が発生

**リスク:** 🟢 低

**推奨対応:**

```terraform
resource "aws_s3_object" "index_html" {
  # 既存の設定...

  lifecycle {
    precondition {
      condition     = fileexists("${path.module}/upload_file/index.html")
      error_message = "index.html が存在しません"
    }

    precondition {
      condition     = filesize("${path.module}/upload_file/index.html") > 100
      error_message = "index.html が空または小さすぎます（最低100バイト必要）"
    }
  }
}
```

**効果:**

- デプロイ前に問題を検出
- 空ファイルのアップロードを防止

**関連タスク:** [TODO.md](TODO.md) - S3/Dashboard - 問題4

---

### 💡 問題5: タグ管理の不統一

**現状:**

- `aws_s3_bucket.dashboard` のみタグを適用
- 他のリソース（versioning, CORS, CloudFront等）にタグがない

**影響:**

- リソースの管理が困難
- コスト配分の追跡が不完全
- AWS Cost Explorerでの分析が不正確

**リスク:** 🟢 低

**推奨対応:**

```terraform
resource "aws_s3_bucket_versioning" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  versioning_configuration {
    status = "Enabled"
  }

  # タグを追加
  tags = var.tags
}

resource "aws_cloudfront_distribution" "dashboard" {
  # 既存の設定...

  tags = merge(
    var.tags,
    {
      Name = "Dashboard CloudFront Distribution"
    }
  )
}
```

**関連タスク:** [TODO.md](TODO.md) - S3/Dashboard - 問題5

---

### 💡 問題6: エラーハンドリングの不足

**現状:**

- `filemd5()` でファイルが存在しない場合のエラーハンドリングがない
- CloudFrontのデプロイ失敗時のロールバック戦略がない

**影響:**

- Terraformの実行が予期せず失敗
- エラーメッセージが不明瞭

**リスク:** 🟢 低

**推奨対応:**

```terraform
locals {
  index_file = "${path.module}/upload_file/index.html"
  index_exists = fileexists(local.index_file)
  index_etag = local.index_exists ? filemd5(local.index_file) : ""
}

resource "aws_s3_object" "index_html" {
  count = local.index_exists ? 1 : 0  # ファイルが存在する場合のみ作成

  bucket       = aws_s3_bucket.dashboard.id
  key          = "index.html"
  source       = local.index_file
  content_type = "text/html"
  etag         = local.index_etag
}
```

**関連タスク:** [TODO.md](TODO.md) - S3/Dashboard - 問題6

---

## 🚀 パフォーマンス関連

### ⚡ 問題7: キャッシュ戦略のトレードオフ

**現状:**

```terraform
default_ttl = 5  # 5秒
```

**トレードオフ:**

- ✅ **メリット:** 最新画像を素早く反映（5秒ごとのリフレッシュ要件に対応）
- ❌ **デメリット:** CloudFrontのキャッシュ効果が限定的
- ❌ **デメリット:** オリジンへのリクエストが頻繁に発生

**影響:**

- CloudFrontのコスト削減効果が小さい
- S3へのリクエスト数が多い
- エッジロケーションの活用が不十分

**リスク:** 🟡 中（コスト面）

**推奨対応案:**

#### オプション1: キャッシュバスティング

```html
<!-- 画像URLにタイムスタンプを付与 -->
<img src="camera1.jpg?t=1706000000" />
```

```terraform
# TTLを長く設定可能
default_ttl = 3600  # 1時間
```

#### オプション2: 条件付きキャッシュ

```terraform
# HTMLは5秒、画像は60秒
ordered_cache_behavior {
  path_pattern     = "*.jpg"
  target_origin_id = "S3-${aws_s3_bucket.dashboard.id}"

  # 画像用のTTL設定
  min_ttl     = 0
  default_ttl = 60
  max_ttl     = 60
}
```

**コスト試算:**

- 現状: CloudFront リクエスト 月間 10,000回 × $0.0075 ≈ $75
- 改善後: CloudFront リクエスト 月間 1,000回 × $0.0075 ≈ $7.5
- **削減額: 約$67/月**

---

### ⚡ 問題8: CloudFront圧縮の限定的な効果

**現状:**

```terraform
compress = true
```

**影響:**

- HTMLファイルは圧縮される
- しかし、画像（JPEG）は圧縮効果が限定的

**リスク:** 🟢 低

**推奨対応:**

- HTMLファイルのサイズを最小化（minify）
- 画像ファイルは事前に最適化（S3アップロード前）
- WebPフォーマットの検討

---

## 📋 未実装機能

### 🔮 問題9: ダッシュボードUIの機能不足

**設計書要件:**

- 全カメラのグリッド表示
- 5秒ごとの自動画像リフレッシュ
- レスポンシブデザイン
- エラーハンドリング

**現状:** 未実装（HTMLファイルが空）

**必要な実装:**

#### index.html の主要機能:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Grandma Alert Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  </head>
  <body>
    <div class="grid-container">
      <!-- カメラ画像のグリッド表示 -->
    </div>

    <script>
      // 5秒ごとのリフレッシュ機能
      setInterval(() => {
        refreshImages();
      }, 5000);
    </script>
  </body>
</html>
```

**関連タスク:** [TODO.md](TODO.md) - S3/Dashboard - 問題7

---

### 🔮 問題10: モニタリング・アラート機能の不足

**現状:**

- CloudWatch アラームが未設定
- エラー率の監視がない
- 異常なアクセスパターンの検知がない

**推奨設定:**

#### CloudFrontエラー率のアラーム:

```terraform
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_errors" {
  alarm_name          = "cloudfront-5xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"  # 5%以上のエラー率でアラート
  alarm_description   = "CloudFront 5xx error rate is too high"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.dashboard.id
  }
}
```

---

## 🎯 S3/Dashboard 優先度別の対応リスト

### フェーズ2: 本番環境前に対応（2週間以内）

1. ⚠️ **CORS設定の厳格化**（問題2）
2. 📊 **アクセスログの設定**（問題3）
3. 💡 **バリデーション機能の追加**（問題4）

### フェーズ3: 品質向上（1ヶ月以内）

4. 💡 **タグ管理の統一**（問題5）
5. 💡 **エラーハンドリングの強化**（問題6）
6. ⚡ **キャッシュ戦略の最適化**（問題7）
7. 🔮 **モニタリング機能の追加**（問題10）

---

# Lambda/GenerateSignedURL モジュール

**作成日:** 2026年1月23日  
**対象モジュール:** `Lambda/GenerateSignedURL`

## 🚨 **現状: デプロイしても動作しません**

**理由:**

- CloudFront Key Pairが未作成（ルートユーザーでの手動作業が必要）
- SSMパラメータストアに秘密鍵が未保存
- CloudFront Distributionに署名検証設定がない

**次にやること:** [TODO.md](TODO.md) - Lambda/GenerateSignedURL - 署名付きURL機能を有効にする手順 を参照

---

## ⚠️ セキュリティ関連（本番環境前に対応）

### ⚠️ 問題1: Lambda Function URLが認証なし

**現状:**

```terraform
authorization_type = "NONE"
```

**影響:**

- **誰でも**Lambda Function URLにアクセス可能
- 署名付きURLを無制限に生成できる
- DoS攻撃のリスク
- コスト爆発の可能性

**セキュリティリスク:** 🔴 高

**推奨対応:**

#### オプション1: IAM認証

```terraform
resource "aws_lambda_function_url" "generate_signed_url" {
  authorization_type = "AWS_IAM"

  cors {
    allow_origins = ["https://<your-domain>.com"]
  }
}
```

**必要な追加実装:**

- Cognito Identity Pool
- IAMロールの割り当て
- クライアント側のSigV4署名

#### オプション2: API Gateway + APIキー

```terraform
resource "aws_api_gateway_rest_api" "signed_url_api" {
  name = "GenerateSignedURL-API"
}

resource "aws_api_gateway_api_key" "api_key" {
  name    = "signed-url-api-key"
  enabled = true
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "signed-url-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.signed_url_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }
}
```

**関連タスク:** [TODO.md](TODO.md) - Lambda/GenerateSignedURL - セキュリティ強化

---

### ⚠️ 問題2: CORS設定が過度に緩い

**現状:**

```terraform
cors {
  allow_origins = ["*"]  # すべてのドメインを許可
}
```

**影響:**

- クロスサイトスクリプティング（XSS）のリスク
- 意図しないドメインからのアクセス
- セキュリティベストプラクティスに反する

**セキュリティリスク:** 🟡 中

**推奨対応:**

```terraform
cors {
  allow_origins = [
    "https://d2zaynqig5sahs.cloudfront.net",
    "https://<your-domain>.com"
  ]
  allow_methods = ["POST"]
  allow_headers = ["content-type", "authorization"]
  max_age       = 86400
}
```

---

### ⚠️ 問題3: レート制限がない

**現状:**

- Lambda Function URLにはレート制限機能がない
- 同一クライアントからの連続リクエストを制限できない

**影響:**

- DoS攻撃のリスク
- Lambda実行回数の急増 → コスト増加
- SSMパラメータストアへの過度なアクセス

**セキュリティリスク:** 🔴 高

**推奨対応:**

#### API Gatewayによるレート制限:

```terraform
resource "aws_api_gateway_usage_plan" "usage_plan" {
  throttle_settings {
    burst_limit = 10   # バースト時の最大リクエスト数
    rate_limit  = 5    # 秒あたりのリクエスト数
  }

  quota_settings {
    limit  = 1000  # 期間内の総リクエスト数
    period = "DAY"
  }
}
```

**関連タスク:** [TODO.md](TODO.md) - Lambda/GenerateSignedURL - レート制限実装

---

### ⚠️ 問題4: CloudFront Key Pairの管理が手動

**現状:**

- CloudFront Key Pairはルートユーザーのみ作成可能
- マネジメントコンソールでの手動操作が必須
- Terraformで管理できない

**影響:**

- インフラのコード化が不完全
- キーローテーションの自動化が困難
- 監査証跡が不十分

**セキュリティリスク:** 🟡 中

**改善案:**

#### 代替案: CloudFront Trusted Key Groups（推奨）

```terraform
# 公開鍵をTerraformで管理可能
resource "aws_cloudfront_public_key" "signed_url_key" {
  name        = "grandma-alert-signed-url-key"
  encoded_key = file("${path.module}/public_key.pem")
}

resource "aws_cloudfront_key_group" "signed_url_key_group" {
  name = "grandma-alert-key-group"
  items = [
    aws_cloudfront_public_key.signed_url_key.id
  ]
}

resource "aws_cloudfront_distribution" "dashboard" {
  # ...
  trusted_key_groups = [
    aws_cloudfront_key_group.signed_url_key_group.id
  ]
}
```

**メリット:**

- Terraformで完全管理
- ルートユーザー不要
- キーローテーションが容易
- 複数のキーを管理可能

**関連タスク:** [TODO.md](TODO.md) - Lambda/GenerateSignedURL - Key Group移行

---

## 🔧 改善提案（品質向上）

### 💡 問題5: エラーハンドリングの不足

**現状:**

```python
except Exception as e:
    print(f"Error generating signed URL: {str(e)}")
    return {
        'statusCode': 500,
        'body': json.dumps({'error': 'Internal server error'})
    }
```

**問題点:**

- すべての例外を500エラーとして返す
- クライアントが原因の場合も500エラー
- エラーの種類が不明瞭

**影響:**

- デバッグが困難
- クライアント側での適切なエラーハンドリングができない

**リスク:** 🟡 中

**推奨対応:**

```python
class SignedURLGenerationError(Exception):
    """署名付きURL生成エラー"""
    pass

class InvalidParameterError(Exception):
    """パラメータエラー"""
    pass

def lambda_handler(event, context):
    try:
        # バリデーション
        if not path:
            raise InvalidParameterError("path is required")

        # 処理...

    except InvalidParameterError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': str(e)})
        }
    except SignedURLGenerationError as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to generate signed URL'})
        }
```

**関連タスク:** [TODO.md](TODO.md) - Lambda/GenerateSignedURL - エラーハンドリング改善

---

### 💡 問題6: ロギングの不足

**現状:**

- エラー時のみログ出力
- 成功時のリクエスト情報が記録されない
- 監査証跡が不十分

**影響:**

- アクセスパターンの把握ができない
- セキュリティインシデントの調査が困難
- 使用状況の分析ができない

**リスク:** 🟡 中

**推奨対応:**

```python
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # リクエスト開始ログ
    logger.info({
        'event': 'signed_url_request',
        'path': path,
        'expiration_minutes': expiration_minutes,
        'source_ip': event.get('requestContext', {}).get('http', {}).get('sourceIp')
    })
```

---

### 💡 問題7: デプロイメントプロセスの改善余地

**現状:**

```terraform
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}
```

**問題点:**

- 依存ライブラリ（cryptography, boto3）が含まれていない
- `requirements.txt` が定義されているが、インストールされていない

**影響:**

- Lambda実行時に `ModuleNotFoundError` が発生する可能性
- デプロイが失敗する

**リスク:** 🔴 高

**推奨対応:**

#### オプション1: Lambda Layer

```terraform
# Layerの作成
resource "null_resource" "install_dependencies" {
  triggers = {
    requirements = filemd5("${path.module}/requirements.txt")
  }

  provisioner "local-exec" {
    command = "pip install -r requirements.txt -t ${path.module}/python"
  }
}
```

**関連タスク:** [TODO.md](TODO.md) - Lambda/GenerateSignedURL - デプロイメント改善

---

## 🚀 パフォーマンス関連

### ⚡ 問題8: コールドスタートの遅延

**現状:**

- コールドスタート時のSSMアクセスが遅い（200-500ms）
- 秘密鍵の読み込みと解析に時間がかかる

**影響:**

- 初回リクエストのレスポンスが遅い
- ユーザー体験の低下

**リスク:** 🟡 中

**推奨対応:**

#### オプション1: プロビジョニング済み同時実行数

```terraform
resource "aws_lambda_provisioned_concurrency_config" "generate_signed_url" {
  function_name                     = aws_lambda_function.generate_signed_url.function_name
  provisioned_concurrent_executions = 1
  qualifier                         = aws_lambda_alias.prod.name
}
```

**コスト試算:**

- プロビジョニング: $0.015/時間 × 24時間 × 30日 ≈ $10.8/月
- メリット: コールドスタート完全排除

---

### ⚡ 問題9: メモリ割り当ての最適化余地

**現状:**

```terraform
memory_size = 128  # MB
```

**影響:**

- メモリが不足する可能性は低い
- しかし、CPUパワーも比例して低い
- 暗号化処理が遅くなる可能性

**リスク:** 🟢 低

**推奨対応:**

実測ベースの最適化を推奨

---

## 📋 未実装機能

### 🔮 問題10: モニタリング・アラート機能の不足

**現状:**

- CloudWatch アラームが未設定
- エラー率の監視がない
- レスポンス時間の追跡がない

**推奨設定:**

```terraform
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "generate-signed-url-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
}
```

---

### 🔮 問題11: テストコードの不足

**現状:**

- ユニットテストがない
- 統合テストがない
- 自動テストのCI/CDパイプラインがない

**影響:**

- バグの早期発見ができない
- リファクタリングが困難
- 品質保証が不十分

**リスク:** 🟡 中

---

## 🎯 Lambda/GenerateSignedURL 優先度別の対応リスト

### フェーズ1: 即座に対応（1週間以内）

1. 🔴 **依存ライブラリのデプロイ修正**（問題7）
2. 🔴 **Lambda Function URLの認証追加**（問題1）
3. 🔴 **レート制限の実装**（問題3）

### フェーズ2: 本番環境前に対応（2週間以内）

4. 🟡 **CORS設定の厳格化**（問題2）
5. 🟡 **エラーハンドリングの改善**（問題5）
6. 🟡 **ロギングの強化**（問題6）

### フェーズ3: 品質向上（1ヶ月以内）

7. 🟡 **CloudFront Key Groupへの移行**（問題4）
8. 🟡 **コールドスタート対策**（問題8）
9. 🔮 **モニタリング機能の追加**（問題10）

---

## 📊 全体リスクマトリクス

| モジュール               | 問題番号 | 問題名                   | 影響度 | 緊急度 | 優先度  |
| ------------------------ | -------- | ------------------------ | ------ | ------ | ------- |
| S3/Dashboard             | 2        | CORS設定が緩い           | 中     | 中     | 🟡 中   |
| S3/Dashboard             | 3        | アクセスログ未設定       | 中     | 中     | 🟡 中   |
| S3/Dashboard             | 4        | バリデーション不足       | 低     | 中     | 🟢 低   |
| S3/Dashboard             | 5        | タグ管理不統一           | 低     | 低     | 🟢 低   |
| S3/Dashboard             | 7        | キャッシュ効率           | 中     | 低     | 🟡 中   |
| Lambda/GenerateSignedURL | 1        | Function URL認証なし     | 高     | 高     | 🔴 最高 |
| Lambda/GenerateSignedURL | 2        | CORS設定が緩い           | 中     | 中     | 🟡 中   |
| Lambda/GenerateSignedURL | 3        | レート制限なし           | 高     | 高     | 🔴 最高 |
| Lambda/GenerateSignedURL | 4        | Key Pair管理が手動       | 中     | 中     | 🟡 中   |
| Lambda/GenerateSignedURL | 7        | 依存ライブラリ未デプロイ | 高     | 高     | 🔴 最高 |

---

## 📚 参考資料

- **プロジェクトTODO:** [TODO.md](TODO.md)
- **設計書:** [Design.md](Design.md)
- **AWS Best Practices:** [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- **CloudFront署名付きURL:** [AWS Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-urls.html)
