# Phase 7: TTS（音声読み上げ）仕様書

> 作成日: 2026-03-21 / ステータス: Draft

---

## 概要

`flutter_tts` パッケージを使い、英単語クイズカードに発音読み上げ機能を追加する。
カード表示時の自動再生 + スピーカーアイコンによるタップ再生の2経路で提供する。

---

## 要件

### 機能要件

1. **自動再生**: クイズカードが表示されるたびに `word.en`（英語）を自動読み上げる
   - ラウンド開始時の第1カード表示時
   - スワイプ後の次カード表示時
   - 出題方向モード（英→日 / 日→英 / ランダム）によらず常に英語を読み上げる

2. **タップ再生**: 各カード右上のスピーカーアイコンをタップすると `word.en` を再再生する
   - アイコンは全方向モードで常に表示

3. **TTS ON/OFF設定**: 設定ダイアログに「発音（TTS）」トグルを追加
   - OFF 時は自動再生・タップ再生ともに動作しない
   - サウンド（BGM/SE）と独立して制御できる
   - デフォルト: ON
   - SharedPreferences キー: `settings_tts_enabled`

### 非機能要件

- `flutter_tts` は iOS / Android 両対応
- TTS の言語設定: `en-US`（英語）固定
- 読み上げ中に新しい再生リクエストが来たら前の再生を停止してから新しく開始する（`stop()` → `speak()`）
- TTS エンジンの初期化失敗時はサイレントに無視（エラー表示なし）

---

## UI/UX 仕様

### クイズカード（`quiz_card.dart`）

- カード右上に小さなスピーカーアイコン (`Icons.volume_up_rounded`) を追加
- アイコンサイズ: 18px、色: `textColor.withValues(alpha: 0.4)`
- タップ時に `onSpeak` コールバックを実行
- `onSpeak` が null のとき（TTS OFF）はアイコンを非表示

```
┌─────────────────────────────────┐
│   [ ↑ 選択肢 ]        [🔊]   │  ← スピーカーアイコン (右上)
│                                 │
│  ← 選択肢  【word.en】  選択肢→ │
│                                 │
│          [ ↓ 選択肢 ]           │
└─────────────────────────────────┘
```

### 設定ダイアログ（`settings_dialog.dart`）

- サウンド・バイブレーション行の下に「発音 (TTS)」トグル行を追加
- アイコン: `Icons.record_voice_over_rounded`
- i18n キー: `settings.tts`（ja: `発音`, en: `Pronunciation`）

---

## 実装方針

### 新規ファイル

| ファイル | 内容 |
|---------|------|
| `lib/until/service/tts_service.dart` | `TtsService` シングルトン（AudioService と同じパターン） |

```dart
class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInitialized() async { ... }
  Future<void> speak(String text) async { ... } // stop → speak
  Future<void> stop() async { ... }
}
```

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `pubspec.yaml` | `flutter_tts` 追加 |
| `lib/features/settings/view_model/settings_view_model.dart` | `ttsEnabled` フィールド + `toggleTts()` + SharedPreferences保存 |
| `lib/features/settings/view/settings_dialog.dart` | TTS トグル行追加 + i18n キー追加 |
| `lib/features/quiz/view/widgets/quiz_card.dart` | `onSpeak: VoidCallback?` パラメータ追加、スピーカーアイコン追加 |
| `lib/features/block_puzzle/view/block_puzzle_screen.dart` | `_QuizLayoutState` でTTS制御（自動再生ロジック） |
| `lib/i18n/ja.i18n.json` / `en.i18n.json` | `settings.tts` キー追加 |

### TTS 自動再生ロジック（`_QuizLayoutState`）

```dart
// ラウンド開始時の第1カード
void _resetForNewRound() {
  // ... existing reset ...
  _speakCurrentCard(0); // 第1カードの自動再生
}

// スワイプ後の次カード
bool _onSwipe(...) {
  // ... existing logic ...
  Future.delayed(const Duration(milliseconds: 300), () {
    if (currentIndex != null) {
      _speakCurrentCard(currentIndex);
    }
  });
}

void _speakCurrentCard(int index) {
  final settings = ref.read(settingsViewModelProvider);
  if (!settings.ttsEnabled) return;
  final questions = ref.read(quizViewModelProvider).questions;
  if (index < questions.length) {
    TtsService.instance.speak(questions[index].word.en);
  }
}
```

---

## 完了条件

- [ ] `flutter_tts` パッケージが `pubspec.yaml` に追加されている
- [ ] `TtsService` シングルトンが動作する（speak / stop）
- [ ] 設定ダイアログに「発音」トグルが表示される（ON/OFF が SharedPreferences に保存される）
- [ ] クイズカード表示時に英語が自動読み上げられる（TTS ON 時）
- [ ] カード右上のスピーカーアイコンをタップすると再読み上げされる（TTS ON 時）
- [ ] TTS OFF 時はスピーカーアイコンが非表示になり自動再生も動作しない
- [ ] 前の読み上げ中に新しいカードが表示されると前の音声が停止する
- [ ] `flutter analyze` でエラーなし
