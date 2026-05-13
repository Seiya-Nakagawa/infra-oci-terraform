#!/bin/bash
# =============================================================================
# Terraform Apply Execution Script (STG環境のみ)
# Usage: ./scripts/tf_apply.sh
# =============================================================================
set -e

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

cd terraform

if [ ! -f "tfplan" ]; then
    echo "❌ 実行計画ファイル (terraform/tfplan) が見つかりません。"
    echo "   先に ./scripts/tf_plan.sh を実行してください。"
    exit 1
fi

echo ""
echo "=========================================="
echo "🚀 Terraform Apply"
echo "=========================================="
terraform apply tfplan

# 適用後は計画ファイルを削除（再利用防止）
rm -f tfplan

echo ""
echo "=========================================="
echo "✅ 適用が完了しました。"
echo "=========================================="
