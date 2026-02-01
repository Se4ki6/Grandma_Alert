# 🚨 Grandma Alert (高齢者緊急通報システム) — 開発者向けREADME

新人参加者がすぐに開発へ参加できるよう、現時点の進捗と作業導線を整理しています。

## 1. プロジェクト概要

高齢者の緊急時に、家族のLINEグループへ「気づくまで画像を送り続ける（通知の嵐）」ことで迅速な初動対応を実現するシステムです。

### 主要コンセプト

- **Continuous Alert:** 5秒間隔で画像を送信
- **Rich Menu Control:** 通報/解除を固定メニューで即時操作
- **Multi-View:** 複数カメラはWebダッシュボードで一覧監視

## 2. 仕様・設計ドキュメント

- 全体設計: [docs/Design.md](docs/Design.md)
- 要件/ロードマップ: [docs/RDD.md](docs/RDD.md)

## 3. 現在の進捗（2026/01/22時点）

### ✅ 完了

- LINE Developers コンソール設定
  - Messaging APIのチャネル作成
  - Webhook URL設定（空でも可）
  - 家族グループLINE作成 & Bot招待
- AWS IoT Core
  - Thing作成: `ElderlyCam_01`
  - 証明書発行 & ダウンロード
  - IoT Policy作成 & アタッチ

### ⏳ 一部未完（値の埋め込み待ち）

- Channel Access Token の記録
- LINE `groupId` の確定
- IoT Core Endpoint の確定

### 🔜 未着手（これからの主要タスク）

- S3バケット作成（画像保存 + Webホスティング）
- DynamoDB作成（通報テンプレート格納）
- RasPi側アプリ実装（MQTT/撮影/アップロード）
- Lambda（通知/コマンド処理）
- LINEリッチメニュー実装
- Webダッシュボード作成

## 4. リポジトリ構成

```
.
├── README.md
├── docs/
│   ├── Design.md
│   └── RDD.md
├── FetchGroupID/          # LINE groupId取得用の基盤(Terraform)
├── IotCore/               # AWS IoT Coreの基盤(Terraform)
```

## 5. 新人向けスタートガイド（最短）

### Step 1: ドキュメント把握

1. [docs/Design.md](docs/Design.md) を通読（全体像）
2. [docs/RDD.md](docs/RDD.md) でロードマップ確認

### Step 2: Terraformディレクトリを確認

- [FetchGroupID/](FetchGroupID/) : LINEグループID取得用のAPIGateway/Lambda一式
- [IotCore/](IotCore/) : IoT Core基盤の定義

### Step 2.5: セットアップ/チュートリアル

ローカル準備の手順はドキュメントに整理しています。該当するOSの手順に従ってください。

- Terraformのインストール手順: [docs/Setup/terraform-setup.md.md](docs/Setup/terraform-setup.md.md)
- AWS CLIのインストールと初期設定（基本 + SSO）: [docs/Setup/aws-cli-setup.md](docs/Setup/aws-cli-setup.md)
- .gitignore対象の秘匿ファイル配布先: [docs/Setup/secret_files.md](docs/Setup/secret_files.md)

SSO利用時は、CLIプロファイルを指定して作業します（例: `$AWS_PROFILE` を設定）。

### Step 3: TODOの中から着手しやすいもの

以下のいずれかに着手するとスムーズです。

1. **S3 + DynamoDB の作成**
2. **RasPi側のPython実装（main.py）**
3. **LINE Webhook/Lambdaの雛形作成**

## 6. 開発の前提（設定値）

下記はまだ確定していないため、作業の際は一時値 or .env で管理してください。

- LINE Channel Access Token
- LINE groupId
- AWS IoT Endpoint

## 7. TODO一覧（現状の抜粋）

詳細は [docs/RDD.md](docs/RDD.md) を参照してください。

- S3バケット作成 & ライフサイクル設定
- DynamoDB `EmergencyInfo` 作成
- RasPi: MQTT + Shadow監視 + 撮影/S3アップロード
- Lambda: S3トリガー → LINE通知
- Lambda: LINE Webhook → Shadow更新/通報テンプレ送信
- リッチメニュー & Web Dashboard

## 8. 運用メモ（重要）

- SDカード寿命対策（ログ量抑制）
- 電源抜け対策（AC固定 or モバイルバッテリー）
- CPU/熱対策（撮影5秒間隔で負荷増）

---

**次にやるべきことが分からない場合**は、[docs/RDD.md](docs/RDD.md) のフェーズ順で進めてください。
