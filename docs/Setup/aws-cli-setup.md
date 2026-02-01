### 2. AWS CLI (バージョン2) のインストール

#### **macOS (GUIインストーラー)**

コマンドラインでも可能ですが、公式のGUIインストーラーが最も確実です。

1. 以下のURLより最新のpkgファイルをダウンロードします。

- [https://awscli.amazonaws.com/AWSCLIV2.pkg](https://www.google.com/search?q=https://awscli.amazonaws.com/AWSCLIV2.pkg)

2. ダウンロードしたファイルを開き、画面の指示に従ってインストールします。

**Homebrewで行う場合（非公式な場合もありますが手軽です）:**

```bash
brew install awscli

```

#### **Windows (MSIインストーラー)**

1. 以下のURLより最新のMSIインストーラーをダウンロードします。

- [https://awscli.amazonaws.com/AWSCLIV2.msi](https://www.google.com/search?q=https://awscli.amazonaws.com/AWSCLIV2.msi)

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

- `AWS Access Key ID`: 用意したアクセスキー
- `AWS Secret Access Key`: 用意したシークレットキー
- `Default region name`: 使用するリージョン（例: `ap-northeast-1` ※東京）
- `Default output format`: `json`

以上で、TerraformからAWSリソースを操作する準備の第一段階が整います。

もし特定のOS（Linuxなど）や、バージョン管理ツール（`tfenv`など）を含めた手順が必要であればお知らせください。

お疲れ！エンジニア仲間として、今のトレンドである `aws configure sso` （最近は IAM Identity Center って呼ぶのが正解だけどね）の手順をまとめたよ。

IAMユーザーのアクセスキーを直書きするのは、現代のエンジニアリングとしては「鍵を玄関マットの下に置く」くらいスリリングな行為だから、SSO（シングルサインオン）を使うのは大正解。サクッと設定しちゃおう！

---

### AWS IAM Identity Center (旧 SSO) の設定方法

この設定を一度済ませれば、長寿命なアクセスキーをローカルに持たなくて済むからセキュリティも安心。以下の手順で進めてみて。

#### **1. 設定の開始**

ターミナルで以下の魔法の言葉を叩こう。

```bash
aws configure sso

```

#### **2. 対話形式での入力内容**

コマンドを打つと色々聞かれるから、以下の感じで埋めていけばOK。

- **SSO session name**: 適当な識別名（例: `my-sso-session`）
- **SSO start URL**: 管理者（または自分）が発行したURL（例: `https://d-xxxxxxxxxx.awsapps.com/start`）
- **SSO region**: SSOインスタンスがあるリージョン（例: `ap-northeast-1`）
- **SSO registration scopes [sso:account:access]**: そのまま **Enter**

#### **3. ブラウザでの認証（ここが一番「今どき」）**

上記を入力すると、ターミナルにコードが表示されて、勝手にブラウザが立ち上がるはず。

1. ブラウザでコードを確認して「Confirm and allow」的なボタンをポチる。
2. AWSにログイン（普段使っているSSO用のメールアドレスとか）。
3. 「成功したよ！」って出たらブラウザは閉じてOK。

#### **4. アカウントとロールの選択**

ターミナルに戻ると、アクセス可能な **AWS Accounts** がリストアップされるよ。

1. 使いたいアカウントを矢印キーで選んで **Enter**。
2. 次に **IAM roles**（AdministratorAccess とか PowerUserAccess とか）が出るから、必要なものを選んで **Enter**。

#### **5. 最後の仕上げ（CLI用プロファイル設定）**

最後にCLIで使う際の設定を聞かれるよ。

- **CLI default client Region**: 使用するメインのリージョン（例: `ap-northeast-1`）
- **CLI default output format**: `json`（これが無難）
- **CLI profile name**: **ここが重要！** `aws` コマンドで使う名前を決めるよ（例: `my-dev-env`）。

---

### 次回からのログイン方法

一度設定してしまえば、セッションが切れた（翌朝とか）ときはこれだけでOK。

```bash
aws sso login --profile my-dev-env

```

これでブラウザがパッと開いて「承認」するだけで、魔法のように認証が完了するよ。

### Terraformで使う場合

Terraformからこの設定を使いたいときは、環境変数をセットするのが一番手っ取り早いよ。

```bash
export AWS_PROFILE=my-dev-env
terraform plan

```

これで「アクセスキーがない！」って怒られずに、平和にリソースが作れるはず。

もし環境変数を毎回打つのが面倒なら、`direnv` とかを使ってディレクトリごとに自動で切り替わるようにするのもアリだね。他にも気になるところがあれば何でも聞いて！

次は、Terraformのコードを書き始める準備（`main.tf` の作成とか）をお手伝いしようか？
