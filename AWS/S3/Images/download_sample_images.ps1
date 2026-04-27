# ============================================
# サンプル画像ダウンロードスクリプト
# ============================================
# テスト用のプレースホルダー画像をダウンロードします
# ============================================

# カラー出力用関数
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "→ $Message" -ForegroundColor Cyan }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Header { param($Message) Write-Host "`n═══ $Message ═══" -ForegroundColor Yellow }

Write-Header "サンプル画像ダウンロード"

# sample_imagesディレクトリを作成
$sampleDir = Join-Path $PSScriptRoot "sample_images"
if (-not (Test-Path $sampleDir)) {
    New-Item -ItemType Directory -Path $sampleDir | Out-Null
    Write-Success "sample_imagesディレクトリを作成しました"
}

# ダウンロードする画像リスト（部屋のテーマに合わせたシード値）
$images = @(
    @{ Name = "living.jpg"; Seed = "living-room-1001"; Description = "リビング" }
    @{ Name = "entrance.jpg"; Seed = "entrance-way-1002"; Description = "玄関" }
    @{ Name = "bedroom.jpg"; Seed = "bedroom-sleep-1003"; Description = "寝室" }
    @{ Name = "hallway.jpg"; Seed = "hallway-corridor-1004"; Description = "廊下" }
)

Write-Info "4枚のサンプル画像をダウンロードします (640x480)"
Write-Info ""

$downloadedCount = 0
$failedCount = 0

foreach ($image in $images) {
    $outputPath = Join-Path $sampleDir $image.Name
    $url = "https://picsum.photos/seed/$($image.Seed)/640/480"
    
    # 既存ファイルのチェック
    if (Test-Path $outputPath) {
        Write-Info "$($image.Name): 既に存在します（スキップ）"
        continue
    }
    
    Write-Info "ダウンロード中: $($image.Description) → $($image.Name)"
    
    try {
        # ダウンロード実行
        Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing -ErrorAction Stop
        
        # ファイルサイズを確認
        $fileInfo = Get-Item $outputPath
        $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
        
        Write-Success "$($image.Name) をダウンロードしました ($fileSizeKB KB)"
        $downloadedCount++
        
        # ダウンロード間隔を設ける（API制限対策）
        Start-Sleep -Milliseconds 500
    }
    catch {
        Write-Error "$($image.Name) のダウンロード失敗: $($_.Exception.Message)"
        $failedCount++
    }
}

Write-Header "ダウンロード結果"
Write-Host "  成功: $downloadedCount 個" -ForegroundColor Green
if ($failedCount -gt 0) {
    Write-Host "  失敗: $failedCount 個" -ForegroundColor Red
}

Write-Info ""
Write-Info "次のステップ:"
Write-Info "  1. sample_imagesフォルダの画像を確認"
Write-Info "  2. 必要に応じて画像を差し替え"
Write-Info "  3. .\upload_test_images.ps1 でS3にアップロード"
Write-Info ""

Write-Success "完了しました！"
