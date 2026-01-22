# FetchGroupID

## 概要

こちらでは、LINEのグループIDを受け取るための処理を行います。
Webhookのレスポンスを受け取るために、Lambdaに簡単なスクリプトを用意します。
下記、別途対応が必要なため、準備をしてください

1. LINE長期アクセストークンの取得(LINE Developersコンソール)
2. Webhookの有効化(LINE Developersコンソール)
3. API GatewayのエンドポイントURLをWebhook URLに張り付け(LINE Developersコンソール)
4. グループに作成した公式アカウントを招待(LINE)
5. CloudWatch Logsのストリームから、GroupIDを特定(AWS)

## 1. tfvars の編集

- `resigon`
- `profile`
- `apigateway_name`

## 2. 実行手順

```
terraform init
terraform plan
terraform apply
```
