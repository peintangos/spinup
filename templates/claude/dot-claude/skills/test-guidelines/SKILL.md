---
name: test-guidelines
description: テスト戦略・ガイドラインを確認する
---

## タスク

テストを書く・レビューする際に、このプロジェクトのテスト戦略とガイドラインを適用する。

## テスト戦略

### 自動テスト

#### 単体テスト（Unit Test）
- vitest で関数レベルのテストを記述する
- 配置: `src/__tests__/unit/**/*.test.ts`
- 実行: `npm run test`

#### 結合テスト（Integration Test）
- mock を使わず、実サーバーを起動して HTTP リクエストで検証する
- 配置: `src/__tests__/integration/**/*.test.ts`
- 実行: `npm run test:integration`

### 手動テスト

- LINE Bot 連携など、自動化が困難な外部サービスとの統合は手動で確認する

## ルール

- テストコードを追加・修正する際は、上記の配置規約に従うこと
- 結合テストでは mock を使わないこと（実サーバーを起動して検証する）
- 詳細なガイドラインは `docs/development-guidelines.md` も参照すること
