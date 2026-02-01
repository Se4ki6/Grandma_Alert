# コードレビュー TODO リスト

**レビュー日時:** 2026年1月22日  
**最終更新:** 2026年2月1日  
**対象:** S3/Dashboard モジュール + 署名付きURL実装

---

## 🚨 重大な問題（即座に対応が必要）

### 1. HTMLファイルが空

- [x] `S3/Dashboard/upload_file/index.html` の実装
- [x] `S3/Dashboard/upload_file/error.html` の実装
- **影響:** 現在、空ファイルがS3にアップロードされるため、静的Webサイトとして機能しない
- **優先度:** 🔴 高

---

## ⚠️ セキュリティ関連（本番環境前に対応）

### 2. パブリックアクセスの制限（署名付きURL方式）

**方針:** Basic認証なし、署名付きURLで一時的なアクセスを許可（緊急時の利便性を優先）

#### 実装手順

- [x] **2.1 S3バケットをプライベート化**
  - [x] `s3.tf` の `aws_s3_bucket_public_access_block` を変更
    ```terraform
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
    ```
  - [x] `aws_s3_bucket_policy.dashboard_public` リソースを削除

- [x] **2.2 CloudFront ディストリビューションの作成**
  - [x] 新規ファイル `S3/Dashboard/cloudfront.tf` を作成
  - [x] Origin Access Control (OAC) の設定
  - [x] S3バケットポリシーにCloudFrontからのアクセスのみ許可
  - [x] Cache設定（画像は5秒でキャッシュ無効化）

- [x] **2.3 Lambda関数で署名付きURL生成**
  - [x] 新規Lambda関数: `GenerateSignedURL`
  - [ ] CloudFront Key Pair の作成（AWSコンソール → CloudFront → Key management）※手動作業
  - [x] 署名付きURLの有効期限を設定（推奨: 10分〜1時間）
  - [x] Lambda実装:
    ```python
    # boto3でCloudFront署名付きURLを生成
    from botocore.signers import CloudFrontSigner
    ```

- [ ] **2.4 通知システムの修正**
  - [ ] `NotifyFamily` Lambda関数を修正
  - [ ] S3画像URLの代わりに、CloudFront署名付きURLを生成してLINE送信
  - [ ] URLの有効期限をメッセージに明示（例: "10分間有効"）

- [ ] **2.5 Dashboard アクセスの署名付きURL化**
  - [ ] API Gateway + Lambda でダッシュボード用署名付きURL発行エンドポイント作成
  - [ ] LINEリッチメニューに「ダッシュボードを開く」ボタン追加
  - [ ] ボタン押下 → 署名付きURL生成 → リダイレクト

- [ ] **2.6 テスト**
  - [ ] 署名なしアクセスが拒否されることを確認
  - [ ] 署名付きURLでアクセス成功を確認
  - [ ] URL有効期限切れ後のアクセス拒否を確認

- **現状:** すべてのリソースに完全パブリックアクセスを許可
- **優先度:** 🟡 中
- **推定工数:** 4-6時間

### 3. CORS設定の厳格化

- [ ] `allowed_origins` を特定のドメインに制限
- **現状:** `allowed_origins = ["*"]` で全ドメインを許可
- **推奨:** 実際に使用するドメインのみ許可
- **優先度:** 🟡 中

---

## 🔧 改善提案（品質向上）

### 4. バリデーション機能の追加

- [ ] Terraform に lifecycle precondition を追加
  ```terraform
  lifecycle {
    precondition {
      condition     = fileexists("${path.module}/upload_file/index.html")
      error_message = "index.html が存在しません"
    }
  }
  ```
- [ ] ファイルサイズのチェック（空ファイル検知）
- **効果:** デプロイ前に問題を検出できる
- **優先度:** 🟢 低

### 5. タグ管理の統一

- [ ] すべてのリソースに `tags` 変数を適用
- [ ] 現在、`aws_s3_bucket.dashboard` のみタグを適用
- [ ] 他のリソース（versioning, CORS設定など）にも適用を検討
- **優先度:** 🟢 低

### 6. エラーハンドリングの強化

- [ ] HTMLファイルが存在しない場合の適切なエラーメッセージ
- [ ] `filemd5()` のエラーハンドリング追加
- **優先度:** 🟢 低

---

## 📝 実装すべき機能（index.html）

### 7. ダッシュボード機能の実装

- [x] カメラ画像のグリッド表示UI
- [x] 5秒ごとの自動画像リフレッシュ機能
- [x] エラー時の適切な表示処理
- [x] レスポンシブデザイン対応
- [x] 画像読み込み失敗時のフォールバック表示
- **設計書要件:** 「全カメラのグリッド表示」「5秒ごとの画像リロード処理」
- **優先度:** 🔴 高
- **完了日:** 2026年1月下旬

### 8. エラーページの実装

- [x] `error.html` の基本的なエラー表示
- [x] 404, 403 などの適切なエラーメッセージ
- [x] ホームページへの戻りリンク
- **優先度:** 🟡 中
- **完了日:** 2026年1月下旬

---

## ✅ 良好な実装（維持）

- ✓ リソース構成が適切（バケット、バージョニング、ポリシー、CORS設定）
- ✓ 静的Webサイトホスティング設定が正しく構成
- ✓ `depends_on` で依存関係を明示的に定義
- ✓ `etag` を使用してファイル変更を検知
- ✓ CORS設定の基本構成が適切

---

## 🎯 推奨実装順序

1. **フェーズ1:** HTMLファイルの基本実装（問題1, 7, 8）✅ **完了**
2. **フェーズ2:** セキュリティ強化（問題2, 3）🔄 **進行中**
   - ✅ 2.1-2.3 完了
   - ⏳ 2.4-2.6 残り作業
3. **フェーズ3:** 品質改善（問題4, 5, 6）

---

## 📚 参考情報

- 設計書: `docs/Design.md`
- 要件定義: プロジェクトルートの README 参照
- セキュリティベストプラクティス: AWS Well-Architected Framework
