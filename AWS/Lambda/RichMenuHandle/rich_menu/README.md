# LINE Rich Menu Setup Scripts

このディレクトリには、LINE Messaging APIを使用してリッチメニューを設定するための一連のPythonスクリプトが含まれています。

## 概要

安否確認システムのためのリッチメニューを作成・設定します。リッチメニューには以下の3つのアクションボタンが含まれます：

1. **通報する** - Postbackアクションでラムダ関数に通知
2. **画像一覧** - S3でホストされた画像一覧ページへ遷移
3. **大丈夫/停止する** - Postbackアクションでラムダ関数に通知

## スクリプト一覧

### 1. create_rich_menu.py
リッチメニューの構造を定義し、LINE Messaging APIを使用してリッチメニューを作成します。
- サイズ：2500px × 1686px（縦3等分）
- 各エリアのアクション設定を含む

### 2. create_simple_image.py
リッチメニュー用の単色画像を生成するユーティリティスクリプトです。
- 指定した色・サイズで画像を生成
- images/フォルダに保存

### 3. upload_image_to_richmenu.py
作成したリッチメニューに画像をアップロードします。
- 画像ファイルをリッチメニューIDに紐付け

### 4. set_default_rich_menu.py
作成したリッチメニューを全ユーザーのデフォルトとして設定します。

## セットアップ

### 前提条件
- Python 3.x
- 必要なパッケージ：requests, python-dotenv, Pillow

### 環境変数設定
`.env`ファイルを作成し、以下の環境変数を設定してください：

```env
LINE_CHANNEL_ACCESS_TOKEN=your_channel_access_token
RICH_MENU_ID=your_rich_menu_id
IMAGE_PATH=./images/your_image.png
```

## 使用方法

### ステップ1: リッチメニューの作成
```bash
python create_rich_menu.py
```
実行後、リッチメニューIDが返されます。このIDを`.env`ファイルの`RICH_MENU_ID`に設定してください。

### ステップ2: 画像の生成（オプション）
```bash
python create_single_color_image.py.py
```
リッチメニュー用の単色画像を生成します。カスタム画像を使用する場合はスキップ可能です。

### ステップ3: 画像のアップロード
```bash
python upload_image_to_richmenu.py
```
リッチメニューに画像をアップロードします。

### ステップ4: デフォルトリッチメニューの設定
```bash
python set_default_rich_menu.py
```
すべてのユーザーのデフォルトリッチメニューとして設定します。

## リッチメニュー構成

```
┌─────────────────────────────────┐
│       通報する (562px)          │  ← Postback: action=report
├─────────────────────────────────┤
│      画像一覧 (562px)           │  ← URI: 画像一覧ページ
├─────────────────────────────────┤
│   大丈夫/停止する (562px)       │  ← Postback: action=stop
└─────────────────────────────────┘
        全体: 2500px × 1686px
```

## 注意事項

- リッチメニューの画像サイズは厳密に2500px × 1686pxである必要があります
- 環境変数が正しく設定されていることを確認してください
- スクリプトは順番に実行する必要があります（特にリッチメニューIDが必要な場合）

## トラブルシューティング

- **401 Unauthorized**: チャネルアクセストークンが正しくない、または期限切れです
- **404 Not Found**: リッチメニューIDが存在しません
- **400 Bad Request**: 画像サイズやフォーマットが不正です
