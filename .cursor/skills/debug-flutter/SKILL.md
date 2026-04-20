---
name: debug-flutter
description: >-
  Flutter/Dart のバグ・エラーを診断して最小変更で修正する。
  「バグ」「エラー」「クラッシュ」「直して」「動かない」「flutter analyze」「overflow」
  「Riverpod」「build_runner」などのキーワードが含まれるときに使用。
---

# Flutter デバッグ手順

## 原則
- **仮説を先に報告** してから修正する（コードを書く前に原因を言語化）
- **最小変更** で直す（バグと無関係のコードは触らない）
- **リファクタは別タスク**（修正だけに集中する）
- 完了条件: `flutter analyze` エラー 0 件

## Phase 1: エラーを分類する

| 分類 | 特徴 |
|---|---|
| `analyze` | lint / 型エラー・コンパイルエラー |
| `runtime` | null / キャスト / 範囲外アクセス |
| `riverpod` | ProviderException / State 不整合 |
| `build_runner` | コード生成失敗・競合ファイル |
| `ui` | RenderFlex overflow / 描画バグ |
| `logic` | 期待と異なる動作・状態遷移の誤り |

## Phase 2: 仮説を提示する（修正前に必須）

```
【分類】analyze / runtime / riverpod / build_runner / ui / logic
【影響箇所】lib/apps/.../xxx.dart:行番号（推定）
【原因仮説】○○が null / watch と read が逆 / copyWith の引数漏れ 等
【修正方針】○行目の△を□に変更する
```

ユーザーが確認したら Phase 3 へ。

## Phase 3: 分類別の修正パターン

### analyze エラー
1. エラーのファイルパス・行番号を確認する
2. `dart fix --apply` で自動修正できるか試す
3. 手動修正が必要な場合は最小変更で対応する

### runtime クラッシュ
1. スタックトレースの先頭（自コード行）を特定する
2. null になりうる箇所に `?.` / `??` / early return を追加する
3. `state.valueOrNull` の null ガードが抜けていないか確認する

### Riverpod エラー
- `ref.watch` は build メソッド内のみ
- `ref.read` はイベントハンドラ内のみ
- `AutoDispose` Provider を dispose 後に参照していないか確認する
- `state.valueOrNull` → null なら即 return（`error-handling.mdc` 参照）

### build_runner 失敗
```bash
dart run build_runner build --delete-conflicting-outputs
```
競合する `.freezed.dart` / `.g.dart` を削除してから再実行する。
`.freezed.dart` / `.g.dart` は直接編集しない。

### RenderFlex overflow
- `Expanded` / `Flexible` の不足を確認する
- `Column` 内に固定高さと可変高さが混在していないか確認する
- `SingleChildScrollView` でラップできないか検討する

### ロジックバグ
1. 問題を再現する最小手順を特定する
2. sealed class（`QuizState` など）の state 遷移を確認する
3. `copyWith` の引数に漏れがないか確認する

## Phase 4: 検証

```bash
flutter analyze
```

エラーが残っていれば Phase 2 に戻る。エラー 0 件になったら完了を報告する。

## 禁止事項
- バグと無関係のコードを触らない
- 新しいパッケージを導入しない
- リファクタリングを同時に行わない
- テストを自動追加しない
