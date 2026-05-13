#!/bin/bash
# =============================================================================
# Terraform Plan Execution Script
# Usage: ./scripts/tf_plan.sh
# 出力はファイルに保存し、サマリーと変更内容をユーザーに提示
# =============================================================================
set -e

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

cd terraform

echo ""
echo "=========================================="
echo "📋 Terraform Format"
echo "=========================================="
terraform fmt -recursive -list=false
echo "✅ Format完了"

echo ""
echo "=========================================="
echo "🔧 Terraform Init"
echo "=========================================="
if ! terraform init; then
    echo "❌ Init が失敗しました。"
    exit 1
fi

echo ""
echo "=========================================="
echo "📊 Terraform Plan"
echo "=========================================="
if ! terraform plan -out=tfplan -no-color > tfplan.log 2>&1; then
    echo "❌ Plan が失敗しました。"
    cat tfplan.log
    exit 1
fi

echo ""
echo "=========================================="
echo "📋 Plan結果サマリー"
echo "=========================================="
grep "Plan:" tfplan.log || true

echo ""
echo "=========================================="
echo "📋 変更内容"
echo "=========================================="
grep -E "^\s*[+~\-] " tfplan.log | head -100 || echo "（変更なし）"

echo ""
echo "=========================================="
echo "✅ Plan完了"
echo "=========================================="
echo ""
echo "詳細は tfplan.log を確認してください"
echo "ユーザーの確認・承認を待っています"
echo ""
