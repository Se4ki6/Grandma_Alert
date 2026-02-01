# LINE通知Lambda関数

## 概要
このモジュールは、AWS Lambdaを使用してLINE Messaging APIを通じてメッセージを送信するシステムです。Grandma_Alertプロジェクトの一部として、LINE Bot経由でユーザーまたはグループに通知を送信します。

## 主な機能
- **LINE API統合**: LINE Messaging APIを使用したメッセージ送信
- **Lambda関数化**: サーバーレス環境での実行
- **CloudWatch Logs統合**: 実行ログの自動記録と監視
- **エラーハンドリング**: 実行時エラーの詳細なログ出力

## ファイル構成
```
LineNotification/
├── lambda.tf          # Lambda関数とIAM設定のTerraform定義
├── output.tf          # 出力値の定義
├── provider.tf        # プロバイダー設定
├── variable.tf        # 変数定義
├── python/
│   └── line.py        # LINE通知の実装コード
└── README.md          # このファイル
```

## 環境変数
以下の環境変数をLambda関数に設定する必要があります：
- `LINE_CHANNEL_ACCESS_TOKEN`: LINEチャネルのアクセストークン
- `GROUP_ID`: メッセージ送信先のグループID（Gから始まるID）
- `USER_ID`: メッセージ送信先のユーザーID（ユーザーへ送信する場合）

## ログ出力
Lambda関数はCloudWatch Logsに以下の情報を出力します：
- 関数の開始・終了
- 送信先ID
- メッセージ内容
- APIレスポンスステータス
- エラー詳細（スタックトレース付き）

ログは[lambda.tf](lambda.tf)の設定に基づいて1日間保持されます。

## 使用方法
1. 環境変数を設定
2. Terraformで構成をデプロイ
3. Lambda関数をトリガー（手動実行またはIoT Coreからのトリガー）
4. CloudWatch Logsで実行結果を確認

## 関連リソース
- [Grandma_Alert README](../../README.md)
- [LINE Messaging API ドキュメント](https://developers.line.biz/ja/api-documentation/messaging-api/)
- [AWS Lambda Python ドキュメント](https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html)
