# ホワイトラベル アーキテクチャ設計

## 概要

「1箇所修正→全アプリ反映」を実現するための3軸抽象化設計。
UI/ロジックは `core` に集約し、アプリパッケージは設定ファイルだけを持つ薄いエントリにする。

## パッケージ構成

```
anki_games/
├── packages/
│   ├── core/                     ← 全アプリ共通（ここを修正するだけで全アプリに反映）
│   │   ├── lib/
│   │   │   ├── config/
│   │   │   │   ├── brand/
│   │   │   │   │   └── brand_config.dart   ← ① ブランド設定抽象（見た目・ID）
│   │   │   │   ├── styles/                 ← セマンティック色のみ（itPass* は app 側へ）
│   │   │   │   ├── theme/                  ← buildAppTheme()
│   │   │   │   └── ads/                    ← AdConfig（注入パターン維持）
│   │   │   └── features/
│   │   │       ├── exam_quiz/              ← ② 試験クイズ機能17 feature（app_it_passから移設）
│   │   │       │   ├── config/
│   │   │       │   │   └── exam_config.dart  ← ③ 試験データ設定抽象
│   │   │       │   ├── model/
│   │   │       │   │   ├── exam_meta.dart    ← app_it_passから移設、パス抽象化
│   │   │       │   │   └── question.dart     ← app_it_passから移設、optional拡張
│   │   │       │   ├── quiz/
│   │   │       │   ├── filter/
│   │   │       │   ├── learning/
│   │   │       │   └── ...（17 feature）
│   │   │       └── quiz/                   ← 既存の英単語クイズ（block_puzzle用・変更なし）
│   │   └── assets/
│   │       └── quiz/
│   │           ├── fe/                     ← 基本情報 JSON（既存）
│   │           └── fp3/                    ← FP3 JSON（既存）
│   │
│   ├── app_it_pass/              ← 薄いエントリ（設定のみ）
│   │   ├── lib/
│   │   │   ├── main.dart         ← ProviderScope で BrandConfig/ExamConfig を override
│   │   │   └── config/
│   │   │       ├── it_pass_brand_config.dart ← ItPassBrandConfig implements BrandConfig
│   │   │       └── it_pass_exam_config.dart  ← ItPassExamConfig implements ExamConfig
│   │   └── assets/
│   │       └── quiz/
│   │           └── it_pass_*.json             ← IT Pass 問題データ（アプリ固有）
│   │
│   ├── app_fe/                   ← 新規（薄いエントリ）
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   └── config/
│   │   │       ├── fe_brand_config.dart       ← FeBrandConfig implements BrandConfig
│   │   │       └── fe_exam_config.dart        ← FeExamConfig implements ExamConfig
│   │   └── assets/
│   │       └── quiz/
│   │           └── fe_*.json                  ← 基本情報 JSON（core から複製）
│   │
│   └── app_block_puzzle/         ← 変更なし（英単語クイズ）
```

## 3軸抽象化

### ① BrandConfig（見た目・ID）

```dart
abstract class BrandConfig {
  String get appName;
  Color get seedColor;
  Color get accentColor;
  Gradient get bgGradient;
  Color get bgSolid;
  String get logoAssetPath;
  AdConfig get adConfig;
  RevenueCatConfig get revenueCatConfig;
  StoreIds get storeIds;
  String get analyticsBrandKey;  // Firebase 共有プロジェクト内のアプリ識別子
}
```

注入: `brandConfigProvider.overrideWithValue(ItPassBrandConfig())`

### ② ExamConfig（試験データ定義）

```dart
abstract class ExamConfig {
  List<ExamMeta> get examList;
  Map<String, List<String>> get categoryTree;
  Set<String> get freeEraIds;
  String get examTypeKey;  // 'it_pass' | 'fe' | 'fp3'
  String get appAssetPackage;  // assets の flutter package 名
}
```

注入: `examConfigProvider.overrideWithValue(ItPassExamConfig())`

### ③ ブランド差分文言

アプリ名・試験名は `ExamConfig`/`BrandConfig` 経由で取得。
オンボーディング文言・名言は各 Config クラスのメソッドで定義。
全文 i18n 化は今回スコープ外（日本語専用アプリのため）。

## 依存グラフ

```
app_it_pass/main.dart
  └── core/features/exam_quiz/  (ItPassExamConfig + ItPassBrandConfig を注入)
        └── core/config/brand/  (BrandConfig 抽象)
              └── core/config/styles/  (セマンティック色のみ)

app_fe/main.dart
  └── core/features/exam_quiz/  (FeExamConfig + FeBrandConfig を注入)
```

## 修正フロー（横展開後）

```
UIバグ修正       → core/features/exam_quiz/ の1ファイルを修正
                  → melos run analyze でエラー確認
                  → golden テストで全ブランドの崩れを検出
                  → 全アプリ同時リリース

新機能追加       → 同上（全アプリに自動展開）

アプリ固有の変更 → 各アプリの Config ファイルのみ変更
```

## Feature 移設の依存順（Step 5）

密結合なため依存順で段階実行する:

```
5a 独立 feature（他から未参照）:
   learning → notification → daily_study_log → review

5b 中依存 feature（5a が終わってから）:
   filter → note → streak → report → backup → profile → purchase → auth

5c ハブ（最後、最大リスク）:
   onboarding → quiz（quiz_view_model の分解 → quiz_screen の整理）
```

各ステップ末で `flutter analyze 0件` + `app_it_pass の既存動作維持` を確認。

## pubspec.yaml 依存管理基準

モノレポ内の各パッケージは以下の3層ルールで依存を管理する。

| 層 | ファイル | 宣言すべき依存 |
|---|---|---|
| **共有ライブラリ** | `packages/core/pubspec.yaml` | アプリ横断で共有する全実装パッケージをここに集約（唯一の真実）。新しいパッケージを追加するときは原則 core に書く |
| **アプリシェル** | `packages/app_*/pubspec.yaml` | `core`（path）と、そのアプリの `lib/` 内で直接 `import 'package:x/...'` するパッケージのみ。core 経由で使えるものは書かない |
| **ビルドホスト** | `pubspec.yaml`（root）| `app_*`（path）+ `flutter`（SDK）のみ。コード生成・lint ツールは dev_dependencies に。直接 import するコードはここに置かない |

**判断の一問一答：**
- core の `lib/` 内で `import 'package:foo/...'` する → core の dependencies に書く
- app の `lib/` 内で直接 import する → そのアプリの dependencies に書く（core にも書く場合は省略不可）
- import せず推移的に使う → 書かない
- コード生成が必要（`build_runner` / `freezed` / `riverpod_generator` 等）→ コードを持つパッケージの dev_dependencies に書く

## Firebase 戦略

- 単一プロジェクト（`anki-quiz-dev`）を共有（現状維持）
- アプリ識別は `analyticsBrandKey`（例: `'it_pass'`, `'fe'`）を Firebase Analytics のユーザープロパティに設定
- Firestore のデータは collection パス内に brand キーを含める（将来の分離を考慮）
