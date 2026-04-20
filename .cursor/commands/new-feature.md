# /new-feature — 新機能のスケルトン生成

新しい feature フォルダ・ViewModel・Screen の雛形を作成します。

## 使い方
```
/new-feature it_pass filter_xxx
/new-feature block_puzzle game_result
```
引数: `{app_name} {feature_name}`
- app_name: `it_pass` または `block_puzzle`
- feature_name: スネークケース（例: `quiz_history`, `settings_v2`）

## 手順

### Step 1: 引数を確認する
- app_name と feature_name が指定されていない場合はユーザーに確認する
- 既に同名の feature が存在しないか `lib/apps/{app_name}/features/` を確認する

### Step 2: フォルダ構造を作成する
以下のパスにファイルを作成:
```
lib/apps/{app_name}/features/{feature_name}/
  model/{feature_name}_state.dart
  repository/{feature_name}_repository.dart
  view/{feature_name}_screen.dart
  view_model/{feature_name}_view_model.dart
```

### Step 3: 各ファイルを生成する

#### `model/{feature_name}_state.dart`
```dart
class XxxxxState {
  const XxxxxState({
    // TODO: フィールドを追加
  });

  XxxxxState copyWith({
    // TODO: フィールドを追加
  }) {
    return const XxxxxState();
  }
}
```

#### `view_model/{feature_name}_view_model.dart`

**it_pass の場合（非同期データ読込あり → AsyncNotifier）:**
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

final AutoDisposeAsyncNotifierProvider<XxxxxViewModel, XxxxxState>
    xxxxxViewModelProvider =
    AsyncNotifierProvider.autoDispose<XxxxxViewModel, XxxxxState>(
  XxxxxViewModel.new,
);

class XxxxxViewModel extends AutoDisposeAsyncNotifier<XxxxxState> {
  @override
  Future<XxxxxState> build() async {
    return const XxxxxState();
  }
}
```

**block_puzzle の場合（同期的な初期化 → Notifier）:**
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

final AutoDisposeNotifierProvider<XxxxxViewModel, XxxxxState>
    xxxxxViewModelProvider =
    NotifierProvider.autoDispose<XxxxxViewModel, XxxxxState>(
  XxxxxViewModel.new,
);

class XxxxxViewModel extends AutoDisposeNotifier<XxxxxState> {
  @override
  XxxxxState build() {
    return const XxxxxState();
  }
}
```

#### `repository/{feature_name}_repository.dart`
```dart
class XxxxxRepository {
  // TODO: メソッドを追加
}
```

#### `view/{feature_name}_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class XxxxxScreen extends ConsumerWidget {
  const XxxxxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(
        child: Text('XxxxxScreen'),
      ),
    );
  }
}
```

### Step 4: 命名を適用する
`Xxxxx` をパスカルケースの feature 名に置き換える（例: `feature_name = quiz_history` → `QuizHistory`）

### Step 5: 確認する
```bash
flutter analyze
```
エラーがないことを確認してから完了とする。

## 注意事項
- `TODO` コメントはユーザーへのガイドとして残す（変更ログコメントではない）
- 既存 feature のパターンを必ず参照する（`lib/apps/{app_name}/features/` 内）
- Router への登録・画面遷移の追加はこのコマンドの対象外（別途対応）
