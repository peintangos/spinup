# spinup

GitHub リポジトリ作成 → clone → devcontainer セットアップを1コマンドで行う CLI ツール。
生成される devcontainer は [Claude Code](https://docs.anthropic.com/en/docs/claude-code) での開発に最適化されている。

## モチベーション

Claude Code で新しいプロジェクトを始めるたびに、以下の作業を毎回手動で行う必要がある:

1. GitHub リポジトリを作成して clone
2. `.devcontainer/` を用意（Dockerfile, devcontainer.json, ファイアウォール設定…）
3. Claude Code CLI のインストールや認証設定

`spinup` はこれらを1コマンドに集約する。

### 設定の使い回し

生成される devcontainer はホストの `~/.claude/` をマウントするため、エージェントやスキルなどのユーザー設定はプロジェクト間で自動的に共有される。

プロジェクト固有の設定（CLAUDE.md）は、devcontainer 起動後に `claude /init` を実行して生成する。

## 前提条件

- macOS
- [GitHub CLI (`gh`)](https://cli.github.com) インストール・認証済み
- `git` インストール済み
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) サブスクリプション（Max / Team / Enterprise）
  - 生成される devcontainer は Claude Code 専用に設計されている

## 使い方

```bash
# 直接実行（完了後、プロジェクトディレクトリで新しいシェルが起動する）
./spinup.sh

# オプション指定
./spinup.sh -n my-project -r node -v 22

# フルオプション
./spinup.sh -n my-project -r python -v 3.12 --public -d "My project" -p ~/projects
```

完了後、プロジェクトディレクトリで新しいシェルが自動的に起動する。
`Ctrl-D` または `exit` で元のディレクトリに戻れる。

> **TIP**: PATH に追加しておくとどこからでも実行できる:
> ```bash
> export PATH="/path/to/spinup:$PATH"
> ```

### オプション

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `-n, --name` | リポジトリ名 | 対話入力 |
| `-r, --runtime` | ランタイム種類 | 対話選択 |
| `-v, --version` | ランタイムバージョン | LTS |
| `-p, --path` | clone先パス | spinup の親ディレクトリ |
| `--public` | 公開リポジトリ | private |
| `-d, --description` | リポジトリ説明 | なし |

<details>
<summary>上級者向け: spinup-init.sh（オプション）</summary>

`.zshrc` に以下を追加すると、`spinup` コマンドとして使える（実行後に現在のシェルで cd する方式）:

```bash
source /path/to/spinup/spinup-init.sh
```

</details>

## devcontainer と Claude Code

生成される devcontainer は Claude Code での開発用に以下を備えている:

- **CLI プリインストール**: Docker イメージ内で `npm install -g @anthropic-ai/claude-code` 済み
- **認証**: 初回 `claude` 実行時にブラウザ経由で OAuth ログイン（VS Code がホストにURLを転送）
- **ファイアウォール**: `api.anthropic.com` をコンテナのファイアウォール許可リストに設定済み
- **設定永続化**: `~/.claude` を Docker ボリュームでマウントし、認証・設定がコンテナ再作成後も保持される
- **エージェント・スキル共有**: ホストの `~/.claude/agents` と `~/.claude/skills` をバインドマウントしてコンテナ内で利用可能

## ビルトインランタイム

| ランタイム | ベースイメージ | LTS |
|-----------|--------------|-----|
| node | `node:<ver>` | 22 |
| python | `python:<ver>` | 3.12 |
| java | `eclipse-temurin:<ver>-jdk` | 21 |
| go | `golang:<ver>` | 1.23 |
| rust | `rust:<ver>` | 1.84 |

## カスタムランタイム追加

`templates/` 配下にファイルを追加するだけで自動検出される:

| ファイル | 必須 | 説明 |
|---------|------|------|
| `dockerfiles/Dockerfile.<name>` | 必須 | `{{VERSION}}` プレースホルダ含む |
| `devcontainer/devcontainer.<name>.json` | 必須 | VS Code 設定 |
| `runtime.conf/<name>.conf` | 必須 | `LTS=` と `OPTIONS=` |
| `gitignore/<name>.gitignore` | 任意 | |
| `firewall-domains/<name>.txt` | 任意 | 1行1ドメイン |
