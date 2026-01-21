
### 2. AWS CLI (バージョン2) のインストール

#### **macOS (GUIインストーラー)**

コマンドラインでも可能ですが、公式のGUIインストーラーが最も確実です。

1. 以下のURLより最新のpkgファイルをダウンロードします。
* [https://awscli.amazonaws.com/AWSCLIV2.pkg](https://www.google.com/search?q=https://awscli.amazonaws.com/AWSCLIV2.pkg)


2. ダウンロードしたファイルを開き、画面の指示に従ってインストールします。

**Homebrewで行う場合（非公式な場合もありますが手軽です）:**

```bash
brew install awscli

```

#### **Windows (MSIインストーラー)**

1. 以下のURLより最新のMSIインストーラーをダウンロードします。
* [https://awscli.amazonaws.com/AWSCLIV2.msi](https://www.google.com/search?q=https://awscli.amazonaws.com/AWSCLIV2.msi)


2. インストーラーを実行し、指示に従って完了させます。

**確認:**

```bash
aws --version

```

---

### 3. 次のステップ：初期設定

インストールが完了したら、AWSへのアクセス権限を設定する必要があります。

1. ターミナル（またはコマンドプロンプト）で以下を実行します。
```bash
aws configure

```


2. 求められる情報を入力します。
* `AWS Access Key ID`: 用意したアクセスキー
* `AWS Secret Access Key`: 用意したシークレットキー
* `Default region name`: 使用するリージョン（例: `ap-northeast-1` ※東京）
* `Default output format`: `json`



以上で、TerraformからAWSリソースを操作する準備の第一段階が整います。

もし特定のOS（Linuxなど）や、バージョン管理ツール（`tfenv`など）を含めた手順が必要であればお知らせください。