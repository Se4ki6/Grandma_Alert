# Sample Images

このフォルダには、ダッシュボードのテスト用サンプル画像を配置します。

## 現在の画像

- `bedroom.jpg` - 寝室用の画像
- `entrance.jpg` - 玄関用の画像

## 必要な画像

ダッシュボードには4つのカメラ（部屋）が設定されています：

| カメラID   | 部屋名   | 推奨画像名     |
| ---------- | -------- | -------------- |
| camera_001 | リビング | living.jpg     |
| camera_002 | 玄関     | entrance.jpg ✓ |
| camera_003 | 寝室     | bedroom.jpg ✓  |
| camera_004 | 廊下     | hallway.jpg    |

## 画像の追加方法

### 1. 手動で画像を配置

このフォルダに `.jpg`, `.jpeg`, `.png` 形式の画像ファイルを配置してください。

### 2. プレースホルダー画像をダウンロード

```powershell
# PowerShellで実行
Invoke-WebRequest -Uri "https://picsum.photos/640/480" -OutFile "living.jpg"
Invoke-WebRequest -Uri "https://picsum.photos/640/480" -OutFile "hallway.jpg"
```

### 3. 既存の画像を複製（テスト用）

```powershell
# PowerShellで実行
Copy-Item "bedroom.jpg" -Destination "living.jpg"
Copy-Item "entrance.jpg" -Destination "hallway.jpg"
```

## S3へのアップロード

親ディレクトリの `upload_test_images.ps1` スクリプトを使用してください：

```powershell
cd ..
.\upload_test_images.ps1
```

スクリプトは自動的にこのフォルダ内の画像を検出し、各カメラIDに割り当ててS3にアップロードします。

## 画像要件

- **フォーマット**: JPG, JPEG, PNG
- **推奨解像度**: 640x480 以上（4:3アスペクト比）
- **最大ファイルサイズ**: 10MB以下推奨
- **用途**: ダッシュボードでのリアルタイム表示

## S3での保存構造

```
s3://grandma-alert-images-bucket-339126664118/
├── camera_001/
│   └── latest.jpg  ← リビングの画像
├── camera_002/
│   └── latest.jpg  ← 玄関の画像
├── camera_003/
│   └── latest.jpg  ← 寝室の画像
└── camera_004/
    └── latest.jpg  ← 廊下の画像
```

各カメラフォルダには必ず `latest.jpg` という名前で画像を配置します。
