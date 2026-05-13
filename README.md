# infra-oci-terraform - OCI Infrastructure

このリポジトリは、Oracle Cloud Infrastructure (OCI) のインフラ構成を管理するためのTerraformプロジェクトです。

## 📋 ドキュメント

* **[要件定義書](docs/01.要件定義/要件定義書.md)**: システムの目的、各種要件（インフラ、コスト、ネットワークなど）
* **[基本設計書](docs/02.設計/基本設計書.md)**: システム構成、リソース設計、制約事項など
* **[Bastionアクセス手順書](docs/03.手順書/Bastionアクセス手順書.md)**: OCI Bastion を経由したセキュアなログイン手順
* **[Terraform Cloud セットアップ](TERRAFORM_CLOUD_SETUP.md)**: Workspace の詳細な設定手順やトラブルシューティング

## 🚀 Terraform Cloud を利用したローカル実行 (CLI-driven workflow)

このプロジェクトでは、Terraform Cloud をリモートバックエンドとして利用し、ローカルから `terraform` コマンドを実行する **CLI-driven workflow** を採用しています。

詳細なセットアップ・実行手順は **[TERRAFORM_CLOUD_SETUP.md](./TERRAFORM_CLOUD_SETUP.md)** を参照してください。

### メリット

✅ **Stateのセキュアな管理**: tfstate が Terraform Cloud 上で暗号化・管理され、ローカルに保持する必要がない
✅ **チーム開発**: Stateのロックと共有が自動管理される
✅ **監査ログ**: Plan/Applyの実行履歴が Terraform Cloud に記録される
✅ **セキュアな環境変数管理**: OCIの認証情報などを Terraform Cloud 側に保持可能
✅ **無料枠**: 個人利用は無料

---

## 💻 実行手順

本プロジェクトは Terraform Cloud を利用した CLI-driven ワークフローを前提としています。

### 1. Terraform Cloud へのログイン

```bash
terraform login
```

※ブラウザが開く（またはURLが表示される）ので、トークンを発行してターミナルに貼り付けます。

### 2. 環境変数の設定 (Terraform Cloud)

Terraform Cloud の GUI にアクセスし、該当 Workspace の Variables に OCI の認証情報（`tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key` など）を登録してください。
※詳細なセットアップ手順は **[TERRAFORM_CLOUD_SETUP.md](./TERRAFORM_CLOUD_SETUP.md)** をご参照ください。

### 3. 初期化と実行

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. 出力の確認

```bash
# 作成されたリソースの情報を表示
terraform output
```

## 🔐 セキュリティ

* **機密情報の管理**: `terraform.tfvars` は `.gitignore` に含まれており、Gitにコミットされません
* **SSH制限**: 本番環境では `allowed_ssh_cidr` を自分のIPアドレスに制限することを推奨
* **API鍵の管理**: 秘密鍵ファイルは適切なパーミッション (600) で保護してください

## 📝 リソースの削除

```bash
terraform destroy

# 確認プロンプトで "yes" を入力
```

## 🔍 トラブルシューティング

### エラー: "Service error:NotAuthorizedOrNotFound"

* Compartment OCIDが正しいか確認
* ユーザーに適切な権限が付与されているか確認

### エラー: "Out of host capacity"

* 別のAvailability Domainを試す
* 別のリージョンを試す
* 時間を空けて再試行

### インスタンスにSSH接続できない

* Security Listのルールを確認
* SSH公開鍵が正しく設定されているか確認
* インスタンスの起動が完了しているか確認 (cloud-initの実行完了まで数分かかる場合があります)

## 📚 参考リンク

* [OCI Provider Documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs)
* [OCI Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
* [Terraform Best Practices](https://www.terraform-best-practices.com/)
