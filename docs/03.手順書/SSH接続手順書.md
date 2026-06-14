# SSH 接続手順書

本プロジェクトでは、許可されたIP（または任意のIP）から Compute インスタンスへ直接 SSH 接続（TCP 22ポート）を行う構成になっています。

## 📋 前提条件

* Compute インスタンスに登録した SSH 鍵（秘密鍵）がローカル端末にあること
* ローカル端末に SSH クライアントがインストールされていること

## 🚀 アクセス手順

SSH 接続を簡単に行うために、接続用スクリプトが用意されています。

### 1. 接続スクリプトの実行

以下のコマンドを実行することで、`terraform output` からインスタンスのパブリックIPアドレスを自動的に取得し、SSH接続を開始できます。

```bash
./scripts/ssh_connect.sh
```

#### オプション

* `-i <key_path>`: デフォルトの秘密鍵（`~/.ssh/id_rsa`）以外の鍵を使用する場合、秘密鍵のパスを指定します。

```bash
./scripts/ssh_connect.sh -i ~/.ssh/my_oci_key
```

### 2. 手動での接続

スクリプトを使わず、直接 SSH コマンドを実行して接続する場合は、以下の手順で行います。

1. **パブリックIPの確認**
   `terraform` ディレクトリで以下のコマンドを実行し、インスタンスのパブリックIPアドレスを確認します。
   ```bash
   cd terraform
   terraform output instance_public_ip
   ```

2. **SSH 接続の実行**
   確認したパブリックIPと管理ユーザー名（デフォルト: `seiya`）を使用して接続します。
   ```bash
   ssh -i ~/.ssh/id_rsa seiya@<INSTANCE_PUBLIC_IP>
   ```

## 💡 トラブルシューティング

* **SSH 接続がタイムアウトする場合**:
  * OCIのセキュリティ・リスト（`terraform/network.tf`）において、ご自身の接続元IPアドレスが `allowed_client_cidr` として正しく許可されているか確認してください。
  * インスタンスの起動が完了しているか確認してください（起動直後はSSH接続ができるまで数分かかる場合があります）。
