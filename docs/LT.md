# 祖母を守るシステムをAWSとTerraformで作った話

**LT発表資料 / 発表時間：15分**

---

## 1. 自己紹介

（自己紹介スライド）

---

## 2. 背景：なぜ作ったのか

### 課題意識

高齢者が一人でいる時間が増えている。転倒・急病など、**「気づくのが遅れる」**リスクは常にある。

- **119番**：本人が判断して電話する必要がある → 動けない状況では詰む
- **一般的な見守りカメラ**：家族が能動的に確認しに行く必要がある
- **携帯電話**：取れない・操作できない場合がある

> 共通の問題：**家族が能動的に動かないと気づけない**

### 解決のコンセプト

> 📢 **「気づくまで画像を送り続ける（通知の嵐）」**

- ボタンひとつで **5秒ごとに現場写真をLINEグループへ自動送信**
- 家族の誰か一人が気づけばいい設計
- **人命優先**：コストやAPI制限は二の次

---

## 3. プロダクト概要：Grandma Alert

```
┌─────────────────────────────────────────────────────────────────┐
│  高齢者がボタンを押す                                            │
│                                                                  │
│  ┌────────────┐        ┌──────────────────────────────────┐    │
│  │  高齢者    │ ────→  │  Raspberry Pi + カメラ + ボタン  │    │
│  └────────────┘        └──────────────────────────────────┘    │
└───────────────────────────────────┬─────────────────────────────┘
                                    │ MQTT
                                    ▼
                              AWS クラウド
                                    │
            ┌───────────────────────┼────────────────────┐
            ▼                       ▼                    ▼
       IoT Core              S3（画像保存）          Lambda
    Device Shadow        ────────────────→       （通知処理）
   （状態管理）                                        │
                                                        ▼
                                              LINE Messaging API
                                                        │
                                                        ▼
                                              👨‍👩‍👧‍👦 家族グループLINE
                                              （通知の嵐）
```

### 3つのコア機能

| 機能 | 内容 |
|---|---|
| **Continuous Alert** | 5秒間隔で現場写真をLINEグループに自動送信 |
| **Rich Menu Control** | LINE固定メニューから「通報」「解除」を即時操作 |
| **Multi-View** | Webダッシュボードで複数カメラの映像を一覧監視 |

---

## 4. 技術選定

### 4-1. AWSアーキテクチャ

#### 全体構成

```
Raspberry Pi（ボタン・カメラ）
    │ MQTT (TLS)
    ▼
AWS IoT Core ＋ Device Shadow     ← 状態管理（alert / monitoring）
    │
    ├─→ S3（画像保存・プライベート）
    │       │ S3イベントトリガー
    │       ▼
    │   Lambda: LineNotification
    │       │ CloudFront署名付きURL生成
    │       └─→ LINE Messaging API → 家族グループ
    │
    └─→ API Gateway（POST /webhook）
            │ LINE Webhook
            ▼
        Lambda: MessageHandle
            ├─→ Device Shadow更新（解除ボタン → 撮影停止）
            └─→ Secrets Manager（通報情報取得）→ LINE送信
```

#### 各サービスの選定理由

**AWS IoT Core + Device Shadow**
- RasPiとクラウド間の状態同期にMQTTを使用
- Device Shadowの **desired/reported** の仕組みにより、RasPiがオフライン中でも復帰後に正しい状態へ収束する
- 「解除ボタンを押した」という情報をRasPiが確実に受け取れる

**Amazon S3 + CloudFront**
- S3は完全プライベート化（パブリックアクセス完全ブロック）
- CloudFront OAC（Origin Access Control）経由でのみアクセス可能
- **CloudFront署名付きURL**で時間制限付き（1時間）の安全な画像配信
- ライフサイクルルールで画像を1日後に自動削除

**AWS Lambda**
- イベント駆動でサーバ管理不要
- `LineNotification`：S3へのアップロードをトリガーにLINE通知
- `MessageHandle`：LINEリッチメニューのPostbackを処理

**AWS Secrets Manager**
- 通報情報（名前・住所・病歴）をKMS暗号化で安全に管理
- Lambdaから実行時に取得 → ソースコードに秘匿情報を含めない

**LINE Messaging API**
- 家族全員が既に使っているツール → 新しいアプリ不要
- グループ通知で全員に即時配信
- リッチメニューで「通報」「解除」の操作UIを固定表示

---

### 4-2. Terraform による IaC

#### なぜTerraformか

チーム開発で複数人がAWSリソースを操作する → **構成の属人化を防ぐ**ために全リソースをコード管理。

| Terraformの利点 | 内容 |
|---|---|
| `terraform plan` | 変更内容を適用前にレビューできる |
| 再現性 | 同じ定義でステージング環境を立ち上げられる |
| バージョン管理 | Gitで構成変更の履歴を追える |

#### ディレクトリ構成の工夫

```
Grandma_Alert/
└── AWS/
    ├── IotCore/            # IoT Core + 証明書
    ├── Lambda/
    │   ├── LineNotification/   # LINE通知Lambda
    │   ├── MessageHandle/      # Webhook処理Lambda + API Gateway
    │   └── GenerateSignedURL/  # 署名付きURL生成Lambda
    ├── S3/
    │   ├── Images/         # 画像保存バケット + CloudFront
    │   └── Dashboard/      # Webダッシュボード + CloudFront
    ├── SecretsManager/     # 通報情報管理
    └── Raspberrypi/
        └── IAM/            # RasPi用IAMロール
```

**機能単位でディレクトリ・stateファイルを分割**
- 変更影響範囲を局所化 → 一部が壊れても他に波及しない
- `terraform apply` が機能ごとに独立して実行できる
- 変数・タグを統一管理し、コスト配分のトレースを容易に

---

## 5. システムの動き（デモ想定）

### 通報フロー

```
① 高齢者がボタンを押す（Zigbeeボタン → Raspberry Pi GPIO）
        ↓
② RasPiがDevice Shadowを monitoring → alert に更新
        ↓
③ カメラで5秒ごとに撮影 → S3にアップロード
        ↓
④ S3イベントがLambda（LineNotification）をトリガー
        ↓
⑤ LambdaがCloudFront署名付きURLを生成し、画像をLINEグループへ送信
        ↓
⑥ 家族が「大丈夫（解除）」ボタンを押す
        ↓
⑦ LINE Webhook → Lambda（MessageHandle）
        ↓
⑧ Device Shadowを alert → monitoring に更新
        ↓
⑨ RasPiが変更を検知し、撮影ループを停止
```

### コスト感

| サービス | 月額（概算） |
|---|---|
| S3（ストレージ + リクエスト） | 約$2.88 |
| CloudFront（配信） | 約$6.90 |
| Lambda（実行） | 約$0.53 |
| IoT Core | 約$0.52 |
| Secrets Manager | 約$0.45 |
| **合計** | **約$11.29（約1,700円）** |

> 撮影は緊急時のみ → 普段の待機コストはほぼゼロ

---

## 6. ハマりどころ・工夫

### Device Shadowを使う意義

単純にMQTTでメッセージを送るだけでは、**RasPiがオフライン中に「解除」が押されると状態がズレる**。

Device Shadowは desired（あるべき状態）と reported（現在の状態）を管理し、RasPi復帰後に差分を自動配信する → 状態の整合性が保証される。

### 通報情報の保管先をDynamoDBからSecrets Managerへ変更

初期設計では通報情報（住所・病歴等）をDynamoDBに入れていたが、**センシティブなデータには専用の秘匿管理サービスを使うべき**という判断からSecrets Managerへ移行。コストはほぼ同等。

### Terraform stateの分割

全リソースを1つのstateで管理するとapplyが重く、影響範囲も大きい。機能単位でディレクトリ・stateを分割することで **変更のスコープを明示的にコントロール**できるようになった。

### S3の完全プライベート化

画像バケットをパブリックアクセス完全ブロック + CloudFront OACのみ許可にすることで、**署名付きURL経由でしか画像を見られない**構成を実現。プレスURL漏洩のリスクを時間制限で低減。

---

## 7. まとめ

### やったこと

- Raspberry Pi + AWS IoT Core + Lambda + LINE Messaging API を連携した緊急通報システムを構築
- 全AWSリソースをTerraformでコード管理（IaC）
- 「人命優先」設計で、コスト・API制限より確実な通知を優先

### 学んだこと

- AWS各サービスの繋ぎ方と、それぞれの責務の切り方
- Terraformは最初しんどいが、チーム開発では手放せない
- Device Shadowは「状態同期」が必要なエッジデバイス連携で強力

### 今後

- 統合テスト（実際に通報してみる避難訓練）
- LINEリッチメニューのビジュアル作成・設定
- 実家に設置して実運用

---

> **リポジトリ：** Grandma Alert
>
> ご清聴ありがとうございました。
