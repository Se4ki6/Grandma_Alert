# Secrets Manager モジュール

## 概要

高齢者緊急通報システム（Grandma Alert）の通報情報を安全に管理するためのAWS Secrets Manager設定です。

> **方針変更:** DynamoDBではなく、Secrets Managerを使用して通報情報を管理する方針に決定しました（2026年2月1日）

## 機能

- 通報情報の安全な格納（KMS暗号化）
- Lambda関数からのセキュアなアクセス
- Terraformによる完全管理

## 格納情報

| 項目    | 説明             |
| ------- | ---------------- |
| name    | 被介護者の名前   |
| address | 住所             |
| disease | 既往歴・持病情報 |

## DynamoDBからの移行理由

1. **セキュリティ強化**
   - KMS暗号化による保護
   - IAMポリシーによるきめ細かいアクセス制御
   - CloudTrailによる監査ログ

2. **コスト最適化**
   - DynamoDB: $0.25/GB/月 + 読み取り/書き込みコスト
   - Secrets Manager: $0.40/シークレット/月（少量データに最適）

3. **運用簡素化**
   - 単一のシークレットで通報情報を管理
   - バージョン管理機能
   - 自動ローテーション（将来対応可能）

## セットアップ

### 1. terraform.tfvars の作成

`terraform.tfvars.template` をコピーして `terraform.tfvars` を作成：

```bash
cp terraform.tfvars.template terraform.tfvars
```

### 2. 値の設定

```terraform
name    = "山田 太郎"
address = "東京都○○区△△町1-2-3"
disease = "高血圧、糖尿病"
region  = "ap-northeast-1"
profile = "AdministratorAccess-339126664118"
```

### 3. デプロイ

```bash
terraform init
terraform plan
terraform apply
```

## Lambda関数からの取得方法

[lambda_associate.md](lambda_associate.md) を参照してください。

### サンプルコード（Python）

```python
import boto3
import json

def get_emergency_info():
    client = boto3.client('secretsmanager', region_name='ap-northeast-1')
    response = client.get_secret_value(SecretId='LineRichMenu')
    secret = json.loads(response['SecretString'])

    return {
        'name': secret['name'],
        'address': secret['address'],
        'disease': secret['disease']
    }
```

## セキュリティ

- KMS暗号化（aws/secretsmanager）
- Lambda関数のみアクセス許可（リソースポリシー）
- CloudTrailによる監査ログ

## ファイル構成

```
SecretsManager/
├── README.md                    # このファイル
├── provider.tf                  # AWSプロバイダー設定
├── sevretsmanager.tf           # シークレット定義
├── variables.tf                 # 変数定義
├── terraform.tfvars.template    # 設定テンプレート
└── lambda_associate.md          # Lambda連携ガイド
```

## 関連ドキュメント

- [プロジェクト概要](../PROJECT_OVERVIEW.md)
- [セキュリティ実装ガイド](../docs/Setup/security-implementation.md)
- [TODOリスト](../docs/Project/Problems/TODO.md)
