# AdMob クイズモード制御 + jaToEn表示改善 仕様書

> 作成日: 2026-03-20 / ステータス: 完了

---

## 概要

2つの高優先度バグを修正する。

1. **AdMob制御**: クイズモードのゲームオーバー時にインタースティシャル広告が表示されてしまう問題を修正する。学習体験の断絶を防ぐ。
2. **jaToEn表示**: 日→英モード時にカード中央の問題文（日本語）が長くなり、フォントサイズが固定のため折り返しや見切れが発生する問題を修正する。AutoSizeTextで自動サイズ調整する。

---

## 要件

### 機能要件

#### 1. AdMob インタースティシャル制御

- クイズモード（`gameState.isQuizMode == true`）のゲームオーバー時は `AdmobInterstitial().loadAndShow()` を呼ばない
- クラシックモード・クエストモードのゲームオーバー時は従来通り表示する
- リワード広告（Continue ボタン用）のロードは既にクイズモード除外済み（変更不要）

#### 2. jaToEn カード表示 — AutoSizeText 適用

- `QuizCard` の問題文テキストを `Text` → `AutoSizeText` に変更する
- `maxFontSize: 28`、`minFontSize: 14`、`maxLines: 3`
- テキストがカード内に収まらない場合は自動的にフォントサイズを縮小する
- enToJa / jaToEn / random すべてのモードで同じ AutoSizeText を使用（モードによる分岐なし）

### 非機能要件

- `auto_size_text` パッケージを `pubspec.yaml` に追加する（未追加のため）
- 既存の `fontFamily: 'Poppins'`・`fontWeight: FontWeight.bold`・`textAlign: TextAlign.center` は維持する

---

## 実装方針

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `lib/features/block_puzzle/view/widgets/game_over_overlay.dart` | `initState` の `AdmobInterstitial().loadAndShow()` 呼び出しに `!gameState.isQuizMode` ガードを追加 |
| `lib/features/quiz/view/widgets/quiz_card.dart` | `Text(question.displayText, ...)` → `AutoSizeText(question.displayText, ...)` に変更。`auto_size_text` をインポート |
| `pubspec.yaml` | `auto_size_text: ^3.0.0` を追加 |

### 変更箇所の詳細

#### game_over_overlay.dart（line 88〜92）

```dart
// Before:
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    AdmobInterstitial().loadAndShow();
  }
});

// After:
if (!gameState.isQuizMode) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      AdmobInterstitial().loadAndShow();
    }
  });
}
```

#### quiz_card.dart（line 80〜91）

```dart
// Before:
Text(
  question.displayText,
  style: TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textColor,
    height: 1.2,
  ),
  textAlign: TextAlign.center,
),

// After:
AutoSizeText(
  question.displayText,
  style: TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textColor,
    height: 1.2,
  ),
  textAlign: TextAlign.center,
  maxLines: 3,
  minFontSize: 14,
  overflow: TextOverflow.ellipsis,
),
```

---

## 完了条件

- [ ] クイズモードのゲームオーバー後、インタースティシャル広告が表示されない
- [ ] クラシックモード・クエストモードのゲームオーバー後、インタースティシャル広告が従来通り表示される
- [ ] jaToEn モード時に長い日本語問題文がカード内に収まる（AutoSizeText で縮小）
- [ ] enToJa モード時の英語問題文表示に影響なし（fontSize 28 のまま、長文でのみ縮小）
- [ ] `flutter analyze` でエラーなし
