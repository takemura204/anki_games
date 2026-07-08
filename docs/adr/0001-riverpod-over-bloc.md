# ADR-0001: 状態管理に BLoC ではなく Riverpod（hooks_riverpod）を採用する

**Status:** Accepted  
**Date:** 2026-04-01（モノレポ移行時に正式化）

## Context

本アプリは複数の非同期データソース（drift / Firestore / SharedPreferences）を組み合わせた状態管理が必要。またオフライン対応・クロスデバイス同期・課金状態の反映など、状態の依存関係が複雑になる。

選択肢として BLoC、旧 Provider（ChangeNotifier）、Riverpod の3つを比較した。

## Decision

**`hooks_riverpod` + `riverpod_generator`（`@riverpod` アノテーション）を採用する。**

ViewModel は原則 `AutoDisposeAsyncNotifier<State>` で実装し、`AsyncNotifierProvider.autoDispose` で公開する。

## Rationale

### BLoC を選ばなかった理由

- Event クラス・State クラス・Bloc クラスの3点セットが毎 feature に必要で、小〜中規模の個人開発では記述量の割に得られる型安全性が過剰。
- `bloc_test` の `expect: () => [...]` 記法は状態が増えるほど管理コストが上がる。
- `AutoDispose` の概念がなく、画面離脱後も Bloc が生き続ける可能性を手動管理する必要がある。

### 旧 Provider（ChangeNotifier）を選ばなかった理由

- `ChangeNotifier` の `dispose` 漏れはリリース後に発覚しにくいバグを生む。
- `context.read<T>()` はウィジェットツリーへの依存が強く、テスト時のモック差し替えが煩雑。

### Riverpod を選んだ理由

| 観点 | 具体的なメリット |
|---|---|
| AutoDispose | `autoDispose` 宣言するだけで画面離脱時に Firestore リスナが自動破棄。メモリリークをアーキレベルで防ぐ |
| テスタビリティ | `ProviderContainer(overrides: [...])` で任意のプロバイダを Fake に差し替え。Widget ツリー不要でロジックだけをテスト可能 |
| コード生成 | `@riverpod` + `riverpod_generator` で定型文ゼロ。provider 名のタイプミスがコンパイルエラーに変わる |
| 依存解決 | `ref.watch(otherProvider)` で宣言的にプロバイダを合成。Provider の伝播を手動管理しなくてよい |

## Consequences

- **良い点**: テスト時の差し替えが `overrides` だけで完結。状態の自動破棄でリソースリークが起きにくい。
- **悪い点**: `riverpod_generator` を使う場合、`build_runner` の実行が必要。コード生成ファイル（`.g.dart`）が増えるため `.gitignore` に含め、CI でも再生成する。
- **悪い点**: 旧来の `FutureProvider` と `@riverpod` 記法が混在すると可読性が下がる。統一化対応中。

## Alternatives Considered

- **Signals（signals_flutter）**: Dart 3 の Records/Patterns との親和性が高いが、2024年時点では安定性・エコシステムが不十分。
- **flutter_bloc**: 大規模チームでの規約統一には有効。本アプリのスコープでは過剰と判断。
