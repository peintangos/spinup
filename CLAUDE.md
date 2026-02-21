# spinup CLI

GitHub リポジトリ作成 → clone → devcontainer セットアップを1コマンドで行う CLI ツール。

## 前提条件

- macOS を前提とした実行環境
- `gh` コマンド（GitHub CLI）がインストール済みであること
- `gh auth login` で GitHub 認証済みであること（未認証の場合は先に実行する）
- `git` がインストール済みであること

## テンプレート規約

新しいランタイムを追加する場合、以下のファイルを `templates/` 配下に配置するだけで `select` メニューに自動表示される:

| ファイル | 必須 | 説明 |
|---------|------|------|
| `dockerfiles/Dockerfile.<runtime>` | 必須 | `{{VERSION}}` プレースホルダを含む |
| `devcontainer/devcontainer.<runtime>.json` | 必須 | VS Code 拡張機能・設定 |
| `runtime.conf/<runtime>.conf` | 必須 | `LTS=` と `OPTIONS=` を定義 |
| `gitignore/<runtime>.gitignore` | 任意 | なければ空の .gitignore |
| `firewall-domains/<runtime>.txt` | 任意 | 1行1ドメイン |
