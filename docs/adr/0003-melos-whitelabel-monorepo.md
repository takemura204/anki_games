# ADR-0003: Melos モノレポ + ホワイトラベル抽象化（BrandConfig / ExamConfig）を採用する

**Status:** Accepted  
**Date:** 2026-05-01

## Context

「ITパスポート」アプリが軌道に乗った後、同じアーキテクチャで「基本情報技術者試験（FE）」「FP3級」などの試験対策アプリを展開したいという事業上の要件が生まれた。

方針の選択肢:
1. 既存アプリをフォーク（コピー）して別アプリを作る
2. 1つのアプリ内で試験を切り替えるフラグを追加する
3. モノレポで共通ロジックを `core` に集約し、アプリパッケージを差し込み設定のみにする

## Decision

**Melos モノレポを採用し、共通ロジックを `packages/core` に集約する。各アプリパッケージは `BrandConfig`（見た目・課金ID）と `ExamConfig`（問題データ定義）を `ProviderScope` の `overrides` で注入するだけの薄い構成にする。**

## Rationale

### フォーク（選択肢1）を選ばなかった理由

- バグ修正のたびに全コピー先にも同じ修正が必要で、修正漏れが発生しやすい。
- アプリ数が増えるほど乗法的にメンテコストが増大する。

### フラグ切り替え（選択肢2）を選ばなかった理由

- `if (isItPass)` / `if (isFe)` が feature コード全体に散らばり、テストが困難になる。
- 新しい試験を追加するたびに既存コードを改変するリスクがある（開放/閉鎖原則の違反）。

### モノレポ + Config 抽象を選んだ理由

- `core` のバグ修正が全アプリに自動で反映される（修正箇所が1つ）。
- 新しい試験アプリの追加コストが `BrandConfig` + `ExamConfig` の2クラスだけで済む。
- Melos の `exec` コマンドで全パッケージの analyze / test / codegen を一括実行できる。

### ProviderScope override での DI

```dart
// app_it_pass/main.dart（薄いエントリの全体）
ProviderScope(
  overrides: [
    brandConfigProvider.overrideWithValue(ItPassBrandConfig()),
    examConfigProvider.overrideWithValue(ItPassExamConfig()),
  ],
  child: const CoreApp(),
)
```

この設計は Riverpod の ADR-0001 で述べたテスタビリティと直接連動する。テスト時は `ProviderContainer(overrides: [...])` で任意の Config を差し込めるため、ブランド固有のテストも同一の仕組みで書ける。

## Consequences

- **良い点**: 修正コストが O(1)（1箇所）から O(n)（n アプリ分）に増えない。Melos による一括タスク管理。
- **良い点**: `core` の API が public に絞られ、アプリパッケージが `core` の内部実装に依存しにくくなる。
- **悪い点**: モノレポ化の後付けで import 置換コストが発生した（反省点: `docs/portfolio_roadmap.md` 12節参照）。
- **悪い点**: Melos の学習コストが若干ある。`dart run melos bootstrap` 忘れによる pub get エラーが発生しやすい。

## Alternatives Considered

- **Flutter flavors のみ**: `flavor` での分岐は UI・ロジック両方に条件分岐が入り、ADR に述べた「フラグ切り替え」の問題が発生する。
- **Nx / Turborepo**: JavaScript/TypeScript 向けで Flutter との相性が悪い。Melos は Dart ネイティブで Flutter との親和性が高い。
