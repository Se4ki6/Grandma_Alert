# DynamoDB (Terraform)

## 構成

DynamoDBテーブルを作成します:

- テーブル名: 管理対象グループ情報
- パーティションキー: `house_id` (String)
- 課金モード: PAY_PER_REQUEST

### スキーマ

| 属性名            | 型     | 説明                       |
| ----------------- | ------ | -------------------------- |
| `house_id`        | String | パーティションキー、家屋ID |
| `address`         | String | 住所                       |
| `chronic_disease` | String | 持病                       |

## 1. tfvars の編集

`dynamodb.tfvars` を編集してください:

- `profile`
- その他必要な設定項目

## 2. 実行手順

```
terraform init
terraform plan -var-file="dynamodb.tfvars"
terraform apply -var-file="dynamodb.tfvars"
```

## 補足

- DynamoDBにはテストデータを1件投入
