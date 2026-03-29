# 開発ドキュメント — Block.

> 最終更新: 2026-03-22（Phase 6.5 WordMode ハブ画面リデザイン）

---

## 技術スタック

| カテゴリ | 技術 |
|---------|------|
| UI フレームワーク | Flutter 3.38.4-stable |
| 状態管理 | Riverpod (`hooks_riverpod`, `riverpod_annotation`) |
| 不変モデル | Freezed v3 (`abstract class` + `_$` mixin) |
| UI フック | `flutter_hooks` |
| ローカル永続化（ゲーム） | `shared_preferences` |
| ローカルDB（学習記録） | Drift (SQLite ORM) |
| カードスワイプ | `flutter_card_swiper` |
| 効果音 | `audioplayers` |
| テーマ | `flex_color_scheme` |
| 広告 | `google_mobile_ads` |
| i18n | slang (`slang_build_runner`) |
| コード生成 | `build_runner`, `riverpod_generator`, `freezed` |
| バージョン管理 | mise (`mise.toml`) |

### 開発コマンド

```bash
# Flutter コマンド（mise 経由）
eval "$(mise activate bash)" && flutter run
eval "$(mise activate bash)" && dart run build_runner build --delete-conflicting-outputs
eval "$(mise activate bash)" && dart analyze
```

---

## アーキテクチャ方針

### フィーチャーベース MVVM

```
lib/features/{feature_name}/
├── model/         # Freezed データモデル・ドメインロジック
├── view_model/    # Riverpod Notifier（状態管理・ビジネスロジック）
└── view/          # Widget（表示のみ）
    └── widgets/   # 再利用可能なウィジェット
```

### Freezed v3 ルール

```dart
// ✅ 正しい記述（Freezed v3）
@freezed
abstract class MyState with _$MyState {
  const factory MyState({...}) = _MyState;
}

// ❌ Freezed v2（古い書き方）
@freezed
class MyState with _$MyState { ... }
```

### Riverpod パターン

```dart
// ViewModel (Notifier)
@riverpod
class MyViewModel extends _$MyViewModel {
  @override
  MyState build() => const MyState();
  // メソッド
}

// ウィジェット
class MyScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myViewModelProvider);
    final notifier = ref.read(myViewModelProvider.notifier);
  }
}
```

### コーディング規約

- `very_good_analysis` による厳格な lint
- パブリックメンバーには doc comment 必須
- `const` を積極的に使用
- `HookConsumerWidget` を画面に使用
- Part ファイルによるウィジェット分割

---

## 機能別 状態管理

### 1. BlockPuzzleViewModel（ゲームコア）

**Provider**: `blockPuzzleViewModelProvider`
**ファイル**: `lib/features/block_puzzle/view_model/block_puzzle_view_model.dart` (1192行)

**関連ユーティリティ（モデル層）**:
- `lib/features/block_puzzle/model/piece_generator.dart` — `generatePieces()`, `canClearLine()`
- `lib/features/block_puzzle/model/quest_board_generator.dart` — `generateQuestBoardAndNoise()`

#### BlockPuzzleState

```dart
@freezed
abstract class BlockPuzzleState with _$BlockPuzzleState {
  const factory BlockPuzzleState({
    // ── ボード ──────────────────────────────────────────
    required List<List<bool>> board,   // 8×8グリッド (true=配置済み)
    required List<Piece?> pieces,       // トレイの3ピース (null=未付与)
    @Default(<(int,int)>{}) Set<(int,int)> clearingCells,   // 消去アニメーション中
    @Default(<(int,int)>{}) Set<(int,int)> lastPlacedCells, // 直前配置セル

    // ── スコア ──────────────────────────────────────────
    @Default(0) int score,
    @Default(0) int highScore,
    @Default(0) int combo,
    @Default(0) int consecutiveNonClearTurns,
    @Default(false) bool isNewHighScore,
    @Default(null) ClearResult? lastClearResult,

    // ── ゲーム状態 ──────────────────────────────────────
    @Default(false) bool isGameOver,
    @Default(true) bool canContinue,           // リワード広告でコンティニュー可能

    // ── 保存ゲーム ──────────────────────────────────────
    @Default(false) bool hasSavedClassicGame,
    @Default(false) bool hasSavedQuestGame,

    // ── クエストモード ──────────────────────────────────
    @Default(false) bool isQuestMode,
    @Default(1) int questLevel,
    @Default(0) int targetScore,
    @Default(false) bool isQuestComplete,
    @Default(1) int maxUnlockedLevel,

    // ── タイムアタックモード ────────────────────────────
    @Default(false) bool isTimeAttackMode,
    @Default(90) int timeAttackRemainingSeconds,
    @Default(false) bool isTimeAttackComplete,
    @Default(false) bool isTimeAttackCountingDown,
    @Default(0) int timeAttackHighScore,

    // ── クイズモード ────────────────────────────────────
    @Default(false) bool isQuizMode,
    @Default(false) bool isQuizPhase,           // クイズフェーズ中かどうか
    @Default(1) int quizMultiplier,             // スコア倍率
    @Default([]) List<QuizWord> sessionCorrectWords,   // 今セッションの正解単語
    @Default([]) List<QuizWord> sessionIncorrectWords, // 今セッションの不正解単語

    // ── エフェクト ──────────────────────────────────────
    @Default(<List<int>>[]) List<List<int>> noiseBoard,
  }) = _BlockPuzzleState;
}
```

#### 公開メソッド

| メソッド | 説明 |
|---------|------|
| `resetGame()` | クラシック新規開始 |
| `resumeClassicGame()` | クラシック再開 |
| `startQuestLevel(int level)` | クエスト開始 |
| `resumeQuestGame()` | クエスト再開 |
| `retryQuestLevel()` | クエスト再挑戦 |
| `startTimeAttack()` | タイムアタック開始 |
| `retryTimeAttack()` | タイムアタック再挑戦 |
| `startQuizMode()` | クイズモード開始（保存データ復元あり） |
| `placePiece(pieceIndex, row, col)` | ピース配置 |
| `canPlacePiece(pieceIndex, row, col)` | 配置可能チェック |
| `endQuizPhase({comboActive})` | クイズフェーズ終了→ブロックフェーズへ |
| `addQuizPiece(slot, {isCorrect, word})` | クイズ結果からピース付与 |
| `continueGame()` | リワード広告後コンティニュー |

#### 永続化（SharedPreferences）

クラシックモード:
```
block_puzzle_board, block_puzzle_pieces, block_puzzle_score,
block_puzzle_combo, block_puzzle_non_clear_turns, block_puzzle_high_score
```

クイズモード:
```
block_puzzle_quiz_board, block_puzzle_quiz_pieces, block_puzzle_quiz_score,
block_puzzle_quiz_combo, block_puzzle_quiz_non_clear_turns,
block_puzzle_quiz_multiplier, block_puzzle_quiz_is_game_over,
block_puzzle_quiz_is_quiz_phase
```

クエストモード:
```
block_puzzle_quest_board, block_puzzle_quest_pieces, block_puzzle_quest_score,
block_puzzle_quest_combo, block_puzzle_quest_non_clear_turns,
block_puzzle_quest_level, block_puzzle_max_unlocked_level
```

タイムアタック: `block_puzzle_ta_high_score`

---

### 2. QuizViewModel（クイズロジック）

**Provider**: `quizViewModelProvider`
**ファイル**: `lib/features/quiz/view_model/quiz_view_model.dart`

#### QuizViewState

```dart
@freezed
abstract class QuizViewState with _$QuizViewState {
  const factory QuizViewState({
    @Default(true) bool isLoading,              // CSV/DBロード中
    @Default([]) List<QuizQuestion> questions,  // 現ラウンドの3問
    @Default(0) int answeredCount,              // 回答済み数 (0〜3)
    @Default([]) List<QuizAnswerResult> answers,// 回答済み結果
    QuizAnswerResult? lastAnswer,               // 直前の正誤（アニメーション用）
    @Default(false) bool isComplete,            // 3問全回答済み
    @Default(QuizDirectionMode.enToJa) QuizDirectionMode directionMode,
    @Default(MasteryRangeFilter.all) MasteryRangeFilter masteryFilter,     // 学習範囲（択一）
    @Default(<LevelFilter>{}) Set<LevelFilter> selectedLevels,             // 資格レベル（複数選択）
    @Default({}) Map<String, MasteryBreakdown> masteryBreakdowns,          // キー: MasteryRangeFilter.name / LevelFilter.name
    @Default(0) int filteredWordCount,         // 組み合わせフィルター後の単語数
    @Default([]) List<WordEntry> wordEntries,  // 全単語+ステージ（単語一覧・ランキング用）
    @Default([]) List<WordEntry> topBestWords, // 得意TOP5（stage≥3, stage降順）
    @Default([]) List<WordEntry> topWorstWords,// 苦手TOP5（stage=1, weight降順）
  }) = _QuizViewState;
}
```

#### WordEntry モデル

```dart
@freezed
abstract class WordEntry with _$WordEntry {
  const factory WordEntry({
    required QuizWord word,   // 単語データ
    required int stage,       // 現在ステージ (0〜5)
    required double weight,   // 現在の出題重み
  }) = _WordEntry;
}
```

#### 内部フィールド（非状態）

```dart
final _rng = Random();
late final WordRecordRepository _repo;
List<QuizWord> _allWords = [];
final _sessionMissedIds = <int>{};  // 不正解単語の一時的な優先出題用
```

#### 公開メソッド

| メソッド | 説明 |
|---------|------|
| `startNewRound()` | 新3問ラウンド生成 |
| `answer(questionIndex, direction)` | 回答処理・weight更新 |
| `clearLastAnswer()` | 正誤フィードバッククリア |
| `setMasteryFilter(filter)` | 学習範囲フィルター変更・SharedPreferences保存 |
| `toggleLevelFilter(level)` | 資格レベルフィルターのトグル・SharedPreferences保存 |
| `selectAllLevels()` | 全レベル選択状態にリセット |
| `setDirectionMode(mode)` | 出題方向変更・問題再生成・SharedPreferences保存 |
| `loadMasteryStats()` | 習熟度内訳・wordEntries・ランキングを再計算 |
| `resetSession()` | `_sessionMissedIds` クリア（新ゲーム開始時） |
| `updateWordStage(wordId, stage)` | 単語のステージを手動更新し内訳を再計算 |

#### 永続化（SharedPreferences）

```
quiz_direction_mode    # QuizDirectionMode.name
quiz_mastery_filter    # MasteryRangeFilter.name
quiz_selected_levels   # List<String>（LevelFilter.name のリスト、空=全レベル）
quiz_swipe_hint_shown  # bool（スワイプヒント初回表示フラグ）
```

#### 永続化（Drift/SQLite）

テーブル: `WordRecords`

| カラム | 型 | 説明 |
|--------|-----|------|
| id | int (PK) | CSV の id と対応 |
| weight | double | 重み（初期 1.0） |
| correctCount | int | 正解累計 |
| incorrectCount | int | 不正解累計 |
| lastSeenAt | DateTime | 最終出題日時 |

#### weight 更新ロジック

```dart
// 正解時
newWeight = (currentWeight * 0.7).clamp(0.1, 5.0)
// 不正解時
newWeight = (currentWeight * 1.5).clamp(0.1, 5.0)
// 次ラウンド優先出題（一時的・DBに保存しない）
pickWeight = _sessionMissedIds.contains(id) ? dbWeight * 2 : dbWeight
```

#### MasteryBreakdown 分類ロジック

```dart
// DBに記録なし → 未学習 (newWords)
// weight ≥ 2.0  → 苦手 (hard)
// weight < 0.5  → 完璧 (perfect)
// その他        → 得意 (good)
```

---

### 3. ThemeViewModel（テーマ）

**Provider**: `themeViewModelProvider`
**ファイル**: `lib/features/block_puzzle/view_model/theme_view_model.dart`
**永続化**: SharedPreferences（テーマ名）

- 現在選択中の `GameTheme` を管理
- `GameTheme` は `CellRenderMode`, `ClearEffectMode`, `BackgroundMode`, 色セット, 効果音パスを持つ

---

### 4. SettingsViewModel（設定）

**Provider**: `settingsViewModelProvider`
**ファイル**: `lib/features/settings/view_model/settings_view_model.dart`
**永続化**: SharedPreferences

| 設定 | キー |
|------|-----|
| サウンドON/OFF | `sound_enabled` |
| バイブレーションON/OFF | `vibration_enabled` |

---

### 5. QuestProgressViewModel（クエスト進捗）

**Provider**: `questProgressViewModelProvider`
**ファイル**: `lib/features/block_puzzle/view_model/quest_progress_view_model.dart`

- 各レベルの目標スコア・クリア状態を管理

---

## 画面間のナビゲーション

```
HomeScreen
├── [クラシック] → BlockPuzzleScreen
├── [クエスト]   → BlockPuzzleScreen
├── [タイムアタック] → BlockPuzzleScreen
└── [英単語モード] → WordRangeSelectorScreen → BlockPuzzleScreen
```

### クイズモードのナビゲーションスタック

```
HomeScreen → WordRangeSelectorScreen → BlockPuzzleScreen
```

| アクション | 動作 |
|----------|------|
| Play Again (クイズ) | `pop()` → WordRangeSelectorScreen |
| Home (クイズ) | `popUntil(isFirst)` → HomeScreen |
| 設定 Restart (クイズ) | `pop() × 2` → WordRangeSelectorScreen |
| 設定 Home | `pop() × 2` → HomeScreen |

---

## クイズ×ブロック フェーズ遷移

```
BlockPuzzleScreen 起動
    │ ref.listen(isQuizPhase) で true を検知
    ↓
quizViewModelProvider.notifier.startNewRound()
    │ 3問生成 → state.questions 更新
    ↓
_QuizLayout 表示 (AnimatedSwitcher)
    │ CardSwiper でスワイプ回答
    ↓
_onSwipe() → answer() → addQuizPiece()
    │ 3問目のスワイプで currentIndex == null
    ↓
endQuizPhase(comboActive: allCorrect)
    │ isQuizPhase = false
    ↓
_BlockLayout 表示 (AnimatedSwitcher)
```

---

## ディレクトリ構成

```
lib/
├── config/
│   ├── constants/
│   │   └── app_urls.dart           # 利用規約・プライバシーURL
│   ├── env/
│   │   ├── .env                    # 環境変数（git ignore）
│   │   └── env.dart                # Envied 生成クラス
│   └── extensions/
│       └── context_extension.dart
│
├── features/
│   ├── admob/
│   │   ├── admob_banner.dart       # バナー広告
│   │   ├── admob_interstitial.dart # インタースティシャル
│   │   └── admob_reward.dart       # リワード広告
│   │
│   ├── block_puzzle/
│   │   ├── model/
│   │   │   ├── board.dart                  # 8×8ボードロジック
│   │   │   ├── game_theme.dart             # テーマ定義（enum + 色 + 効果音）
│   │   │   ├── game_themes.dart            # 全テーマリスト
│   │   │   ├── piece.dart                  # ピース定義
│   │   │   ├── piece_generator.dart        # ピース生成ロジック
│   │   │   └── quest_board_generator.dart  # クエスト盤面生成ロジック
│   │   ├── view_model/
│   │   │   ├── block_puzzle_view_model.dart  # メインVM
│   │   │   ├── quest_progress_view_model.dart
│   │   │   └── theme_view_model.dart
│   │   └── view/
│   │       ├── block_puzzle_screen.dart      # メイン画面
│   │       ├── modals/
│   │       │   └── theme_selector_sheet.dart
│   │       ├── painters/
│   │       │   └── cell_renderer.dart        # カスタムペインター
│   │       └── widgets/
│   │           ├── background_effect_widget.dart
│   │           ├── board_widget.dart
│   │           ├── countdown_overlay.dart
│   │           ├── game_over_overlay.dart    # ゲームオーバー表示
│   │           ├── piece_tray_widget.dart
│   │           ├── piece_widget.dart
│   │           ├── quest_success_overlay.dart
│   │           ├── score_hud_widget.dart
│   │           ├── theme_block_preview.dart
│   │           └── time_attack_result_overlay.dart
│   │
│   ├── quiz/
│   │   ├── db/
│   │   │   └── app_database.dart   # Drift DB定義・WordRecords テーブル
│   │   ├── datasource/
│   │   │   └── csv_word_datasource.dart  # CSV → QuizWord リスト変換
│   │   ├── model/
│   │   │   ├── quiz_word.dart      # 単語マスタ (id/en/ja/category/level)
│   │   │   └── quiz_result.dart    # 回答結果
│   │   ├── repository/
│   │   │   ├── word_record_repository.dart       # abstract interface
│   │   │   └── local_word_record_repository.dart # Drift 実装
│   │   ├── view_model/
│   │   │   └── quiz_view_model.dart  # クイズロジック・SRS
│   │   └── view/
│   │       ├── word_range_selector_screen.dart  # 学習範囲選択
│   │       └── widgets/
│   │           ├── direction_chip.dart    # 4方向選択肢チップ
│   │           ├── dot_indicator.dart     # 進捗ドット
│   │           ├── quiz_card.dart         # スワイプカード
│   │           └── quiz_result_overlay.dart
│   │
│   ├── home/
│   │   ├── view/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   │       └── mode_card.dart
│   │   └── view_model/
│   │
│   └── settings/
│       ├── view/
│       │   └── settings_dialog.dart  # 設定ボトムシート
│       └── view_model/
│           └── settings_view_model.dart
│
├── i18n/
│   ├── ja.i18n.json
│   ├── en.i18n.json
│   └── translations.g.dart  # slang 生成ファイル
│
├── until/
│   └── service/
│       └── audio_service.dart    # 効果音再生サービス
│
└── main.dart                      # エントリーポイント
```

---

## シェーダー

```
shaders/block_puzzle/
├── glassmorphism.frag
├── wireframe.frag
├── matte.frag
├── bubble.frag
├── ice.frag
├── slate.frag
└── slime.frag
```

---

## コード生成後の確認

モデル変更後は必ず以下を実行:

```bash
eval "$(mise activate bash)" && dart run build_runner build --delete-conflicting-outputs
eval "$(mise activate bash)" && dart analyze
```

Freezed / Riverpod の `.freezed.dart` / `.g.dart` はすべてコード生成ファイル（git 管理下だが手動編集禁止）。
