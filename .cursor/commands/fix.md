# /fix — バグ・エラー修正

エラーメッセージまたはランタイムログを貼り付けて呼び出します。

## 使い方
```
/fix {エラーメッセージ or ランタイムログをここに貼り付ける}
```

## 手順

### Step 1: エラーを分類する

受け取ったエラーを以下のいずれかに分類する:
- `flutter analyze` エラー（lint / 型エラー）
- ランタイムクラッシュ（null safety / 型キャストなど）
- Riverpod エラー（ProviderException / StateNotifier の誤用など）
- build_runner 失敗（コード生成エラー）
- UI レイアウト崩れ / RenderFlex overflow
- ロジックバグ（期待と異なる動作）

### Step 2: 原因仮説を先に報告する

コードを変更する前に、以下の形式で仮説を提示する:

```
【エラー種別】lint / runtime / riverpod / build_runner / ui / logic
【影響ファイル】lib/apps/.../xxx.dart（推定）
【原因仮説】〇〇が null になっている / Provider の watch/read が逆になっている 等
【修正方針】最小変更で〇〇を修正する
```

ユーザーが「進めて」と言ったら Step 3 へ。

### Step 3: 最小変更で修正する

- **バグと無関係のコードは触らない**
- **新しいパッケージを導入しない**
- **リファクタリングは行わない**（別タスクとして切り出す）
- 変更行数を最小限にする

### Step 4: flutter analyze を実行する

```bash
flutter analyze
```

エラーが残っていれば Step 2 に戻り、再度仮説を立てて修正する。
エラー 0 になったら完了を報告する。

## エラー種別ごとの診断ヒント

### flutter analyze エラー
- エラーメッセージのファイルパスと行番号を確認する
- `dart fix --apply` で自動修正できるケースを先に試す

### ランタイムクラッシュ
- スタックトレースの最上部（自分のコード行）を特定する
- `?.` / `??` / null ガードが必要な箇所を探す

### Riverpod エラー
- `ref.watch` は build 内のみ・`ref.read` はイベントハンドラ内のみ
- `AutoDispose` Provider を dispose 後に参照していないか確認する
- `state.valueOrNull` で null ガードが抜けていないか確認する

### build_runner 失敗
```bash
dart run build_runner build --delete-conflicting-outputs
```
- `.freezed.dart` / `.g.dart` の競合ファイルを削除してから再実行する

### RenderFlex overflow
- `Expanded` / `Flexible` の不足、または固定サイズと `Column` の組み合わせを確認する
- `SingleChildScrollView` でラップできないか検討する

### ロジックバグ
- 問題が起きる最小の再現手順を特定する
- 状態遷移（`QuizState` の sealed class など）を確認する
