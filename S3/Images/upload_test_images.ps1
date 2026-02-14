# ============================================
# S3 テスト画像アップロードスクリプト
# ============================================
# 使い方: .\upload_test_images.ps1
# ============================================

# 設定
$BUCKET_NAME = "grandma-alert-images-bucket-339126664118"
$PROFILE = "AdministratorAccess-339126664118"
$REGION = "ap-northeast-1"

# カラー出力用関数
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "→ $Message" -ForegroundColor Cyan }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Header { param($Message) Write-Host "`n═══ $Message ═══" -ForegroundColor Yellow }

# ============================================
# メイン処理
# ============================================

Write-Header "S3テスト画像アップロード開始"

# 現在のディレクトリを確認
$currentDir = Get-Location
Write-Info "現在のディレクトリ: $currentDir"

# 画像ファイルを検索（優先順位: sample_images → カレントディレクトリ → スクリプトディレクトリ）
$imageFiles = @()
$searchDirs = @(
    (Join-Path $PSScriptRoot "sample_images"),  # 1. sample_imagesサブフォルダ
    $currentDir,                                 # 2. 現在のディレクトリ
    $PSScriptRoot                               # 3. スクリプトのディレクトリ
)

foreach ($dir in $searchDirs) {
    if (Test-Path $dir) {
        $foundFiles = Get-ChildItem -Path "$dir\*" -Include *.jpg, *.jpeg, *.png -File -ErrorAction SilentlyContinue
        if ($foundFiles.Count -gt 0) {
            $imageFiles = $foundFiles
            Write-Success "$dir から $($imageFiles.Count)個の画像ファイルを発見しました"
            break
        }
    }
}

if ($imageFiles.Count -eq 0) {
    Write-Error "画像ファイルが見つかりません"
    Write-Info ""
    Write-Info "以下のいずれかの場所に .jpg, .jpeg, .png ファイルを配置してください:"
    Write-Info "  1. sample_images/ フォルダ (推奨)"
    Write-Info "  2. スクリプトと同じディレクトリ"
    Write-Info "  3. 現在のディレクトリ: $currentDir"
    Write-Info ""
    Write-Info "または、download_sample_images.ps1 を実行してサンプル画像をダウンロードしてください"
    exit 1
}

Write-Success "$($imageFiles.Count)個の画像ファイルを発見しました"
Write-Info ""

# カメラIDと画像のマッピング
$cameraMapping = @{
    "camera_001" = @{ Name = "リビング"; File = $null }
    "camera_002" = @{ Name = "玄関"; File = $null }
    "camera_003" = @{ Name = "寝室"; File = $null }
    "camera_004" = @{ Name = "廊下"; File = $null }
}

# 利用可能な画像を表示
Write-Header "利用可能な画像"
$index = 1
foreach ($file in $imageFiles) {
    Write-Host "  [$index] $($file.Name)" -ForegroundColor White
    $index++
}

Write-Info ""

# 画像をカメラに割り当て（自動または手動）
# 自動割り当て: sample_imagesの画像を順番にカメラに割り当て
$assignedCount = 0
$imageIndex = 0

foreach ($cameraId in $cameraMapping.Keys | Sort-Object) {
    if ($imageIndex -lt $imageFiles.Count) {
        $cameraMapping[$cameraId].File = $imageFiles[$imageIndex]
        $assignedCount++
        $imageIndex++
    }
}

# 割り当て結果を表示
Write-Header "カメラと画像の割り当て"
foreach ($cameraId in $cameraMapping.Keys | Sort-Object) {
    $camera = $cameraMapping[$cameraId]
    $fileName = if ($camera.File) { $camera.File.Name } else { "(画像なし)" }
    $color = if ($camera.File) { "Green" } else { "DarkGray" }
    Write-Host "  $cameraId ($($camera.Name)): $fileName" -ForegroundColor $color
}

Write-Info ""

# 確認プロンプト
Write-Host "上記の割り当てでS3にアップロードしますか？" -ForegroundColor Yellow
$confirmation = Read-Host "[Y/n]"
if ($confirmation -ne "" -and $confirmation -ne "Y" -and $confirmation -ne "y") {
    Write-Info "アップロードをキャンセルしました"
    exit 0
}

# ============================================
# S3へのアップロード
# ============================================

Write-Header "S3へのアップロード開始"

$uploadedCount = 0
$failedCount = 0

foreach ($cameraId in $cameraMapping.Keys | Sort-Object) {
    $camera = $cameraMapping[$cameraId]
    
    if (-not $camera.File) {
        Write-Info "$cameraId ($($camera.Name)): スキップ（画像なし）"
        continue
    }
    
    $sourceFile = $camera.File.FullName
    $s3Key = "$cameraId/latest.jpg"
    $s3Uri = "s3://$BUCKET_NAME/$s3Key"
    
    Write-Info "アップロード中: $($camera.Name) ($($camera.File.Name)) → $s3Key"
    
    try {
        # AWS CLIでアップロード
        $result = aws s3 cp $sourceFile $s3Uri --profile $PROFILE --region $REGION 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$($camera.Name) のアップロード成功"
            $uploadedCount++
        }
        else {
            Write-Error "$($camera.Name) のアップロード失敗: $result"
            $failedCount++
        }
    }
    catch {
        Write-Error "$($camera.Name) のアップロード失敗: $($_.Exception.Message)"
        $failedCount++
    }
}

# ============================================
# 結果サマリー
# ============================================

Write-Header "アップロード結果"
Write-Host "  成功: $uploadedCount 個" -ForegroundColor Green
if ($failedCount -gt 0) {
    Write-Host "  失敗: $failedCount 個" -ForegroundColor Red
}

Write-Info ""
Write-Info "ダッシュボードでの確認:"
Write-Info "  1. S3/Dashboard/upload_file/index.html をブラウザで開く"
Write-Info "  2. CloudFront経由でアクセスする場合: CloudFrontのURL"
Write-Info ""
Write-Info "S3バケットの確認:"
Write-Info "  aws s3 ls s3://$BUCKET_NAME/ --recursive --profile $PROFILE"
Write-Info ""

Write-Success "完了しました！"
