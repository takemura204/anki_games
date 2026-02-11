#!/bin/bash

# 引数チェック
if [ -z "$1" ]; then
  echo "Error: Feature name is required."
  exit 1
fi

NAME=$1

# 命名規則の変換 (hoge -> Hoge)
# Perlを使用して snake_case を PascalCase に変換 (hoge_fuga -> HogeFuga 対応)
PASCAL_NAME=$(echo "$NAME" | perl -pe 's/(^|_)./uc($&)/ge;s/_//g')

# ディレクトリ定義
BASE_DIR="lib/features/$NAME"
VIEW_DIR="$BASE_DIR/view"
WIDGET_DIR="$VIEW_DIR/widgets"
VM_DIR="$BASE_DIR/view_model"
MODEL_DIR="$BASE_DIR/model"

# ディレクトリ作成
mkdir -p "$VIEW_DIR"
mkdir -p "$WIDGET_DIR"
mkdir -p "$VM_DIR"
mkdir -p "$MODEL_DIR"

echo "📂 Generating files for feature: $NAME ($PASCAL_NAME)..."

# 1. view/$name_screen.dart
cat <<EOF > "$VIEW_DIR/${NAME}_screen.dart"
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/${NAME}/view_model/${NAME}_view_model.dart';
import 'package:mono_games/features/${NAME}/model/${NAME}_model.dart';


part 'widgets/${NAME}_widget.dart';

class ${PASCAL_NAME}Screen extends HookConsumerWidget {
  const ${PASCAL_NAME}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(${NAME}ViewModelProvider);
    final vm = ref.read(${NAME}ViewModelProvider.notifier);
    final d = ref.watch(${NAME}ModelProvider);
    final m = ref.read(${NAME}ModelProvider.notifier);
    return Scaffold(body: _${PASCAL_NAME}Widget());
  }
}
EOF

# 2. view/widgets/$name_widget.dart
cat <<EOF > "$WIDGET_DIR/${NAME}_widget.dart"
part of '../${NAME}_screen.dart';

  class _${PASCAL_NAME}Widget extends StatelessWidget {
    const _${PASCAL_NAME}Widget();

    @override
    Widget build(BuildContext context) {
      return Text('Sample Widget');
    }
  }
EOF

# 3. view_model/$name_view_model.dart
cat <<EOF > "$VM_DIR/${NAME}_view_model.dart"
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '${NAME}_view_model.freezed.dart';
part '${NAME}_view_model.g.dart';

@freezed
abstract class ${PASCAL_NAME}State with _\$${PASCAL_NAME}State {
  const factory ${PASCAL_NAME}State({
    @Default(false) bool isLoading,
  }) = _${PASCAL_NAME}State;
}

@riverpod
class ${PASCAL_NAME}ViewModel extends _\$${PASCAL_NAME}ViewModel {
  @override
  ${PASCAL_NAME}State build() {
    return ${PASCAL_NAME}State();
  }
}
EOF

# 4. model/$name_model.dart
# 注意: Promptにあった重複するViewModel定義は削除し、純粋なModel定義に修正しています
cat <<EOF > "$MODEL_DIR/${NAME}_model.dart"
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '${NAME}_model.freezed.dart';
part '${NAME}_model.g.dart';

@freezed
abstract class ${PASCAL_NAME} with _\$${PASCAL_NAME} {
  const factory ${PASCAL_NAME}({
    @Default(false) bool isLoading,
  }) = _${PASCAL_NAME};
}

@riverpod
class ${PASCAL_NAME}Model extends _\$${PASCAL_NAME}Model {
  @override
  ${PASCAL_NAME} build() {
    return ${PASCAL_NAME}();
  }
}
EOF

echo "✅ Files created successfully."

# Flutterコマンドの実行
echo "🚀 Running flutter pub get..."
flutter pub get

echo "🔨 Running build_runner (this may take a while)..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "🎉 All done! Feature '$NAME' is ready."