# infra-oci-terraform - OCI Infrastructure

このリポジトリは、Oracle Cloud Infrastructure (OCI) のインフラ構成を管理するためのTerraformプロジェクトです。

## 📋 要件定義

### システムの目的

個人開発における複数のサービスを公開・稼働させるための共通基盤を OCI 上に構築する。
将来的な機能拡張やコンテナの稼働も見据え、十分なリソースを確保しつつ運用コストを最適化する。

### インフラ要件

* **コスト要件**: ランニングコストを最小限に抑えるため、OCI の Always Free 枠（VM.Standard.A1.Flex、200GB Boot Volume など）を最大限に活用する。
* **パフォーマンス・リソース要件**: ARM アーキテクチャの A1.Flex シェイプを利用し、4 OCPU / 24GB RAM の高いスペックを確保する。OS は長期サポート版の Ubuntu 24.04 LTS を採用する。
* **ネットワーク・セキュリティ要件**:
  * インターネット経由での Web アクセス（HTTP:80, HTTPS:443）を許可する。
  * 運用管理のためのセキュアな経路として、OCI Bastion サービスを利用したアクセス基盤を設ける。（インターネットからの直接の SSH 接続は許可しない）
* **運用・保守要件**:
  * インフラの構成管理は Terraform を用いてコード化し、再現性を担保する。
  * CLI-driven workflow を前提とし、ローカルから `terraform login` を経由して実行する運用とする。
  * Terraform (cloud-init) による初期化は OS レベルの最小限の設定（タイムゾーン、管理ユーザーの作成と SSH 鍵登録）に留め、ミドルウェアやアプリケーションの詳細な構成管理は Ansible 等の構成管理ツールへ委譲する。

## 🏗️ 基本設計

### システム構成概要

インターネットから Internet Gateway を経由してアクセス可能な Public Subnet 内に、Compute Instance を単一構成で配置します。

### リソース設計

#### 1. ネットワーク (VCN)

* **VCN / サブネット**: Public Subnet × 1構成
* **ルーティング**: デフォルトルート (`0.0.0.0/0`) を Internet Gateway に向ける。
* **セキュリティリスト (ファイアウォール)**:
  * **Ingress (受信)**: TCP 80 (HTTP), TCP 443 (HTTPS), ICMP (Ping) ※SSH(TCP:22)は直接許可せずBastion経由
  * **Egress (送信)**: すべてのトラフィック (`0.0.0.0/0`) を許可

#### 2. コンピュート (Compute Instance)

* **シェイプ**: `VM.Standard.A1.Flex` (ARM64, 4 OCPU, 24 GB RAM)
* **OS イメージ**: Ubuntu 24.04 LTS (ARM64)
* **ストレージ (Boot Volume)**: 200 GB (Always Free 枠の最大値)
* **ネットワーク**: Public Subnet に配置し、パブリック IP を自動割り当て。
* **初期化設定 (cloud-init)**:
  * タイムゾーンを `Asia/Tokyo` に設定。
  * 管理ユーザーを作成し、sudo 権限および docker グループを付与。
  * SSH 公開鍵を `authorized_keys` に登録。
* **Oracle Cloud Agent**: Bastion 用プラグインを有効化。

#### 3. セキュリティ・管理機能

* **OCI Bastion Service (STANDARD)** を Public Subnet に配置し、動的なクライアント IP 環境からでもセキュアにコンピュートインスタンスへアクセス可能とする。

### 制約事項・前提条件

* 本構成は OCI Always Free 枠の制限事項（コンピュートリソース、ブロックボリューム容量など）に依存している。
* Terraform 側でのインスタンス破棄（`destroy`）時は Boot Volume も併せて削除される（誤操作防止のため `prevent_destroy = true` 設定あり）。
* ミドルウェア等のプロビジョニングは、本番運用においては Ansible 等を用いて実行する前提。

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
