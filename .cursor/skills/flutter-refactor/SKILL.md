---
name: flutter-refactor
description: >-
  anki_games プロジェクトの Flutter コードをリファクタリングする。
  Widget 分割・ViewModel 整理・Repository 共通化・Model 整理・import 整理・命名統一を対象とする。
  "リファクタリングして" "整理して" "/refactor" と言われたとき、
  またはファイルが長くなりすぎた・重複コードが発生したときに使用。
---

# Flutter リファクタリング手順

## 原則

- **ロジックは変えない** — 構造だけ変える。振る舞いを壊さない
- **1ステップ = 1ファイルまたは1クラス** — 一度に大量変更しない
- **feature フォルダ単位** — 1セッションで1 feature を対象とする
- 完了後に必ず `flutter analyze` を実行してエラー0を確認する
- 不要コメントは同時に削除する（変更ログ・内容説明コメント）

## Phase 1: 対象を把握する

1. 対象 feature のファイル一覧を確認:
   ```
   lib/apps/{app}/features/{feature}/
     model/
     repository/
     view/
     view/widgets/
     view_model/
   ```
2. 各ファイルの行数・依存関係を把握する
3. 問題箇所を特定してリストアップ:
   - 200行超のファイル
   - 重複しているロジック
   - 命名が規則に合っていないクラス/変数
   - 不要なコメント

**ユーザーに確認**: リストを提示し、リファクタリング対象と優先順位を合意する

## Phase 2: Widget 分割

`view/` の大きな build メソッドを分割する。

### ルール
- `part 'widgets/xxxxx.dart';` を view ファイルに追加
- `view/widgets/` に private クラスとして定義（`class _XxxxxWidget`）
- 基底クラスは `ConsumerWidget`（hooks 不要）または `HookConsumerWidget`（hooks 必要）
- `StatefulWidget` は使わない

### 分割の目安
- 80行を超えた Widget は分割を検討
- 再利用される Widget は必ず分割

### 例（filter_sheet.dart パターンを参照）
```dart
// view/filter_sheet.dart
part 'widgets/filter_handle.dart';
part 'widgets/filter_header.dart';

// view/widgets/filter_handle.dart
part of '../filter_sheet.dart';

class _FilterHandle extends StatelessWidget {
  const _FilterHandle();
  @override
  Widget build(BuildContext context) { ... }
}
```

## Phase 3: ViewModel 整理

`view_model/` のロジックを整理する。

### チェックポイント
- State クラスに `copyWith` が実装されているか
- `state.valueOrNull` を使った null チェックが抜けていないか
- `scheduleMicrotask` が必要な非同期処理に使われているか
- `ref.read(provider.notifier)` でメソッド呼び出し、`ref.watch` で購読

### 抽出パターン
- 50行超の private メソッドは別クラスや Repository に移動を検討
- ただし **不必要な抽象化は追加しない**

## Phase 4: Repository 整理

- 重複した fetch ロジックは共通メソッドに抽出
- `abstract class` + `impl class` パターンが既存にある場合は踏襲
- 新しいパターンを独自導入しない

## Phase 5: Model 整理

- `copyWith` を持たないモデルには追加する
- freezed 移行は別タスクとして切り出す（このセッションでは行わない）
- `.freezed.dart` / `.g.dart` は直接編集しない

## Phase 6: import 整理

各ファイルの import を以下の順に整頓:
1. `dart:` 系
2. `package:` 系（アルファベット順）
3. `package:anki_games/` 系（アルファベット順）
4. `part of` は import の後

## Phase 7: 検証

```bash
flutter analyze
```

エラー・警告が 0 件になるまで修正してから完了とする。

## 禁止事項（再確認）
- テストを自動追加しない
- UI の見た目・挙動を変えない
- ファイル名・クラス名の一括リネームはしない
- 新パッケージを導入しない
- 過剰なファイル分割をしない
