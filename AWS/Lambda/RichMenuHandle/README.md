# RichMenuHandle

## 概要

`RichMenuHandle/rich_menu`に用意されたスクリプトを使って、あらかじめ指定されたグループチャット用のリッチメニューをLINEプラットフォーム上に作成・管理します。
その上で、リッチメニューからPOSTBACKアクションを実行した場合の処理を行うLAMBDA・APIを構築します。

## 作成手順

1. `RichMenuHandle/rich_menu`のREADMEに従って、リッチメニューを作成し、画像をアップロードしてデフォルトリッチメニューとして設定します。
2. Terraformを使用して、API GatewayとLAMBDA関数をデプロイします。
3. リッチメニューにて、POSTBACLの宛先URLをAPI Gatewayのエンドポイントに設定します。

### リッチメニュー設定の手順
1. LINE Developersコンソール にログインします。
2. 対象の 「プロバイダー」 を選択し、さらにその中の 「チャネル（Bot）」 をクリックします。
3. 上部にあるタブから 「Messaging API設定」 を選択します。
4. 画面を少し下にスクロールすると 「Webhook URL」 という項目があるので、そこの「編集」ボタンを押してURLを入力・保存してください。

## Python構成

`RichMenuHandle/rich_menu/README.md`を参照してください。

## Terraform構成

- APIGATEWAY：リッチメニューのPOSTBACKアクションを受け取る単一エンドポイント
- LAMBDA：POSTBACKアクションを処理する関数
    - `report`:
        - 以下のテンプレートを環境変数から取得して、LINE MESSAGE APIを使用してグループチャットにメッセージを送信します。
        ```text
        [119番テンプレート]
        救急です
        名前は(name)で住所は(address)です。
        既往症は(disease)です
        ```

    - `stop`:
        - グループチャットに「通報を停止しました」というメッセージを送信します。

## 依存関係図

```
┌─────────────┐
│  LINE User  │
│ (Family)    │
└──────┬──────┘
       │ Rich Menu
       │ POSTBACK
       ▼
┌──────────────────────────────────┐
│   API Gateway (POSTBACK受信)      │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  Lambda (postback_handler.py)    │
│                                  │
│  ├─ report action →              │
│  │  └─ LINE Message API (送信)   │
│  │                               │
│  └─ stop action →                │
│     └─ LINE Message API (送信)   │
└──────────┬───────────────────────┘
           │
           ▼
      ┌─────────┐
      │ LINE    │
      │ Message │
      │  API    │
      └─────────┘
```

### 依存関係の詳細

| コンポーネント | 機能 | 依存先 | 説明 |
|---|---|---|---|
| postback_handler.py | POSTBACKイベント処理 | LINE Message API | ユーザーのリッチメニュー操作を受け取り、対応するアクションを実行 |
| LINE Message API | メッセージ送信 | - | グループチャットへの通報・停止メッセージ送信 |
| API Gateway | HTTPエンドポイント | Lambda | LINEからのPOSTBACKリクエストを受け取ってLambdaにルーティング |