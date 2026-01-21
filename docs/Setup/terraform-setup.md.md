TerraformとAWS CLIのインストール方法について、主要なOS（macOSおよびWindows）での手順をまとめました。

---

### 1. Terraformのインストール

Terraformのバージョン管理を行う場合、`tfenv`（Terraform version manager）の利用も一般的ですが、ここでは最新版を直接インストールする標準的な手順を記載します。

#### **macOS (Homebrewを使用)**

ターミナルを開き、以下のコマンドを順に実行してください。HashiCorp公式のTapリポジトリを使用します。

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

```

**確認:**

```bash
terraform -version

```

#### **Windows (Chocolateyを使用)**

パッケージマネージャーのChocolateyを使用すると管理が容易です。PowerShellを管理者権限で開き、以下を実行します。

```powershell
choco install terraform

```

※Chocolateyを使用しない場合は、[HashiCorp公式サイト](https://developer.hashicorp.com/terraform/install)からバイナリをダウンロードし、パス（Path）を通してください。

---
