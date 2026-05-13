# OCI Bastion 経由でのアクセス手順

本プロジェクトでは、セキュリティの観点からインターネット経由での直接の SSH 接続（TCP 22ポート）を許可していません。
Compute インスタンスへログインする場合は、**OCI Bastion サービス** を経由してアクセスする必要があります。

## 📋 前提条件

* OCI コンソールへのログイン権限があること
* Compute インスタンスに登録した SSH 鍵（秘密鍵・公開鍵）がローカル端末にあること
* ローカル端末に SSH クライアントがインストールされていること

## 🚀 アクセス手順

OCI CLI を使用して、セッションの作成と SSH 接続を自動化する手順です。

### 1. 前提条件

* ローカル端末に [OCI CLI](https://docs.oracle.com/ja-jp/iaas/Content/API/SDKDocs/cliinstall.htm) がインストールおよび初期設定（`oci setup config`）されていること。
* `jq` コマンドがインストールされていること。

### 2. セッション作成・接続スクリプト

以下のシェルスクリプト (`bastion_connect.sh` 等) を作成・実行することで、セッションの作成から SSH 接続までをワンストップで行えます。

```bash
#!/bin/bash

# --- 設定値 ---
BASTION_ID="ocid1.bastion.oc1... (BastionのOCID)"
TARGET_INSTANCE_ID="ocid1.instance.oc1... (ComputeインスタンスのOCID)"
OS_USERNAME="seiya"
SSH_PUB_KEY_FILE="$HOME/.ssh/id_rsa.pub"
SSH_PRIV_KEY_FILE="$HOME/.ssh/id_rsa"
# -------------

echo "Bastion セッションを作成しています..."

# セッションを作成し、アクティブになるまで待機して詳細を JSON で取得
SESSION_JSON=$(oci bastion session create-managed-ssh \
  --bastion-id "$BASTION_ID" \
  --target-resource-id "$TARGET_INSTANCE_ID" \
  --target-os-username "$OS_USERNAME" \
  --ssh-public-key-file "$SSH_PUB_KEY_FILE" \
  --wait-for-state SUCCEEDED \
  --wait-interval-seconds 10)

# JSON から SSH コマンドを抽出
SSH_COMMAND=$(echo "$SESSION_JSON" | jq -r '.data."ssh-metadata".command')

if [ -n "$SSH_COMMAND" ] && [ "$SSH_COMMAND" != "null" ]; then
  # <privateKey> の部分を実際の秘密鍵のパスに置換
  EXEC_COMMAND="${SSH_COMMAND/<privateKey>/$SSH_PRIV_KEY_FILE}"
  
  echo "セッションが作成されました。SSH 接続を開始します..."
  eval "$EXEC_COMMAND"
else
  echo "エラー: SSH コマンドの取得に失敗しました。"
  exit 1
fi
```

> [!TIP]
> Terraform を使用しているため、`BASTION_ID` や `TARGET_INSTANCE_ID` の部分を `terraform output -raw bastion_id` のように書き換え、出力を動的に取得するように工夫すると、ハードコードを避けることができます。

## 💡 トラブルシューティング

* **「プラグインが有効になっていません」というエラーが出る場合**:
  Compute インスタンスの Oracle Cloud Agent で「Bastion」プラグインが無効になっている可能性があります。Compute インスタンスの詳細画面から「Oracle Cloud Agent」タブを開き、Bastion プラグインを有効化してしばらく待ってから再度セッションを作成してください。
* **SSH 接続がタイムアウトする場合**:
  Bastion セッションは作成から一定時間（通常 3 時間）で期限切れとなります。期限切れのセッションは削除し、新しくセッションを作り直してください。
