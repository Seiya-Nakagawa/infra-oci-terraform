# OCI Bastion 経由でのアクセス手順

本プロジェクトでは、セキュリティの観点からインターネット経由での直接の SSH 接続（TCP 22ポート）を許可していません。
Compute インスタンスへログインする場合は、**OCI Bastion サービス** を経由してアクセスする必要があります。

## 📋 前提条件

* OCI コンソールへのログイン権限があること
* Compute インスタンスに登録した SSH 鍵（秘密鍵・公開鍵）がローカル端末にあること
* ローカル端末に SSH クライアントがインストールされていること

## 🚀 アクセス手順 (OCI コンソール経由)

最も簡単で推奨される、OCI コンソールから「マネージド SSH セッション」を作成してログインする手順です。

### 1. Bastion 画面へのアクセス

1. OCI コンソールにログインします。
2. 左上のハンバーガーメニューを開き、**「アイデンティティとセキュリティ」** > **「要塞 (Bastion)」** を選択します。
3. 対象のコンパートメントを選択し、作成済みの Bastion リソース（例: `news-check-bastion`）をクリックします。

### 2. セッションの作成

1. Bastion の詳細画面で、**「セッション」** タブをクリックします。
2. **「セッションの作成」** ボタンをクリックします。
3. 以下の設定を入力します：
   * **セッション・タイプ**: `管理対象SSHセッション`
   * **ターゲット・リソース**: 対象の Compute インスタンス（例: `news-check-app-server`）を選択
   * **ターゲット・ユーザー名**: コンピュートインスタンスの OS ユーザー名（デフォルト: `seiya` または `ubuntu`）を入力
   * **SSH キー**: ローカル端末にある SSH 公開鍵 (`.pub` ファイル) を選択、または貼り付けます
4. **「セッションの作成」** をクリックします。

### 3. SSH 接続の実行

1. セッションのステータスが **「アクティブ」** になるまで待ちます（数分かかる場合があります）。
2. アクティブになったら、セッションの右側にある「アクション」メニュー（3つの点）をクリックし、**「SSHコマンドのコピー」** を選択します。
3. ローカルのターミナルを開き、コピーしたコマンドを貼り付けます。
   * ※ コマンド内の `<privateKey>` の部分を、実際の秘密鍵のパス（例: `~/.ssh/id_rsa`）に置き換えてください。

**実行例:**

```bash
ssh -i ~/.ssh/id_rsa -o ProxyCommand="ssh -i ~/.ssh/id_rsa -W %h:%p -p 22 ocid1.bastionsession.oc1... (省略) ...@host.bastion.ap-osaka-1.oci.oraclecloud.com" seiya@10.0.1.x
```

これで、インスタンスへのセキュアなログインが完了します。

## 💻 アクセス手順 (OCI CLI 経由 / 自動化)

毎回コンソール画面を開くのが手間な場合、OCI CLI を使用してセッションの作成と SSH 接続を自動化できます。

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
