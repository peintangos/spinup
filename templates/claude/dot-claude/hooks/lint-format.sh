#!/bin/bash
set -euo pipefail

# stop_hook_active チェック: 無限ループ防止
# Stop hook は stdin に JSON を受け取る
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# 変更された .ts ファイルを取得（tracked + untracked）
MODIFIED=$(git diff --name-only --diff-filter=ACMR HEAD -- '*.ts' 2>/dev/null || true)
UNTRACKED=$(git ls-files --others --exclude-standard -- '*.ts' 2>/dev/null || true)

FILES=$(echo -e "${MODIFIED}\n${UNTRACKED}" | sort -u | sed '/^$/d')

if [ -z "$FILES" ]; then
  exit 0
fi

# 存在するファイルのみに絞る
EXISTING_FILES=""
while IFS= read -r f; do
  if [ -f "$f" ]; then
    EXISTING_FILES="${EXISTING_FILES}${f}"$'\n'
  fi
done <<< "$FILES"
EXISTING_FILES=$(echo "$EXISTING_FILES" | sed '/^$/d')

if [ -z "$EXISTING_FILES" ]; then
  exit 0
fi

# Prettier で整形
echo "$EXISTING_FILES" | xargs npx prettier --write 2>/dev/null

# ESLint --fix で自動修正
LINT_OUTPUT=$(echo "$EXISTING_FILES" | xargs npx eslint --fix 2>&1) || {
  echo "$LINT_OUTPUT" >&2
  exit 2
}

exit 0
