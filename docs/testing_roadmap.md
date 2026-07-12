# テスト学習ロードマップ（未経験者向け）

> **目的**: テストを1行も書いたことがないエンジニアが、このリポジトリを教材にして
> 「テストを書ける」「面接でテストについて話せる」状態になるための段階式カリキュラム。
>
> **使い方**: Phase 0 から順に進む。各 Phase には「学ぶこと → リポジトリの実物 → 手を動かす課題 → 面接で話せること → チェック」がある。チェックボックスを埋めながら進める。
>
> **関連**: テスト全体の方針は [docs/testing.md](testing.md)、設計は [docs/architecture.md](architecture.md) を参照。

---

## ゴール（このドキュメントを終えたとき）

- [ ] テストの種類（Unit / Widget / Integration）を自分の言葉で説明できる
- [ ] AAA（Arrange-Act-Assert）パターンでテストを書ける
- [ ] このリポジトリのテストを自分で1本追加して `flutter test` を通せる
- [ ] Riverpod の `ProviderContainer(overrides:)` でモックを差し替えられる
- [ ] 面接で「テストはどう書きますか？」「何をテストしますか？」に答えられる

所要目安：**1日30分 × 2週間**。焦らず1 Phase ずつ。

---

## 全体像（テストピラミッド）

```
        ╱╲        Integration (E2E)  … アプリ全体を起動して操作。遅いが本物に近い
       ╱  ╲       Widget             … 画面1つを描画してタップ・表示を確認
      ╱────╲      Unit               … 関数・クラス単体。速くて壊れにくい。一番多く書く
```

**覚える結論**: 「下（Unit）を厚く、上（E2E）を薄く」。理由は下ほど**速く・原因特定しやすい**から。
このリポジトリも Unit 中心（49本中ほとんどが Unit / Widget）。

---

## Phase 0 — テストとは何か（コードを書く前に）

### 学ぶこと
- **テスト = 「入力 X を渡したら 出力 Y になる」を自動で検証するコード**。
- なぜ書くか：①リファクタしても壊れていないと保証できる ②仕様が読める ③手動確認の時間が消える。
- 用語3つだけ覚える：
  - `test('説明', () { ... })` … テスト1件
  - `expect(実際の値, 期待する値)` … 検証
  - `group('まとまり名', () { ... })` … テストのグループ化

### リポジトリの実物
`packages/core/test/features/exam_quiz/learning/model/learning_level_test.dart` を**読むだけ**。

```dart
test('null のとき unseen を返す', () {
  expect(LearningLevel.fromStats(null), LearningLevel.unseen);
});
```
→「`fromStats` に `null` を渡したら `unseen` が返るはず」を検証しているだけ、と分かればOK。

### 手を動かす課題
- [ ] 上記ファイルを開いて、各 `test` が「何を・何になると期待しているか」を声に出して説明する

### 面接で話せること
> 「テストは『この入力ならこの出力になる』を自動検証するコードです。手動確認と違い、リファクタ後も毎回同じ基準で壊れていないか確認できます。」

---

## Phase 1 — 環境を整えて既存テストを走らせる

### 学ぶこと
- テストの実行コマンド。
- 「緑（pass）」「赤（fail）」の読み方。

### コマンド
```bash
cd packages/core
flutter test                                   # 全テスト実行
flutter test test/features/exam_quiz/learning/model/learning_level_test.dart  # 1ファイルだけ
```

### 手を動かす課題
- [ ] `flutter test` を実行し `All tests passed!` を確認する
- [ ] `learning_level_test.dart` の `expect` の期待値をわざと間違った値に書き換えて、**赤くなる**のを見る（failの読み方を体感）
- [ ] 元に戻して緑に戻す

### 面接で話せること
> 「`flutter test` でパッケージ全体のテストを回しています。CI でも毎 push 実行され、落ちたらマージできない運用です。」

---

## Phase 2 — 純粋ロジックの Unit テストを書く（一番大事）

### 学ぶこと
- **AAA パターン**：
  - **Arrange**（準備）：入力データを用意
  - **Act**（実行）：テスト対象を呼ぶ
  - **Assert**（検証）：`expect` で結果を確認
- 「純粋ロジック」= 外部（DB・通信・時間）に依存しない関数。**テストが一番簡単なのでここから**。

### リポジトリの実物
`learning_level_test.dart` と `quiz_question_ordering_test.dart`。
`LearningLevel.fromStats` は「学習統計 → 5段階バッジ」を返す純粋関数。

```dart
test('誤答 > 正答のとき weak を返す', () {
  const stats = QuestionLearningStats(correctCount: 1, wrongCount: 3); // Arrange
  final level = LearningLevel.fromStats(stats);                       // Act
  expect(level, LearningLevel.weak);                                  // Assert
});
```

### 手を動かす課題（自分でテストを1本足す）
- [ ] `learning_level_test.dart` に、まだテストされていない境界値を1つ足す
  - 例：「`correctCount: 10, wrongCount: 0` のとき `mastered` を返す」
- [ ] `flutter test` で緑を確認

### 面接で話せること
> 「まず外部依存のない純粋なドメインロジック（習熟度判定や出題順アルゴリズム）から Unit テストを書きました。AAA パターンで、特に分岐の境界値（正答率65%ちょうど、など）を重点的にカバーしています。」

---

## Phase 3 — 非同期 + 外部依存をモックする

### 学ぶこと
- `async / await` を使うテストは `() async { ... }` と書き、`await` で結果を待つ。
- **SharedPreferences はテスト用のモックに差し替えられる**：`SharedPreferences.setMockInitialValues({})`。
- `setUp(() { ... })` … 各テストの前に毎回走る初期化処理。

### リポジトリの実物
`local_streak_repository_test.dart`。

```dart
setUp(() {
  SharedPreferences.setMockInitialValues({}); // 毎テスト前に保存領域を空にする
});

test('初回学習でストリークが 1 になる', () async {
  final result = await repo.recordStudy(DateTime(2026, 6)); // await で待つ
  expect(result.currentStreak, 1);
});
```

ポイント：
- `setUp` で毎回リセットするから、テスト同士が干渉しない（**テストは独立しているべき**）。
- `DateTime(2026, 6)` のように**時間を引数で渡す設計**だからテストできる（`DateTime.now()` を内部で呼ぶとテストが不安定になる）。

### 手を動かす課題
- [ ] `local_streak_repository_test.dart` に「4日連続でストリークが4になる」テストを足す
- [ ] `setUp` をコメントアウトして実行し、テストが互いに干渉して落ちるのを観察 → 戻す

### 面接で話せること
> 「外部依存（永続化）は SharedPreferences のモックに差し替えてテストします。`setUp` で毎回ストレージをリセットしてテストの独立性を担保しています。また時刻は引数で注入する設計にして、テストの再現性を確保しました。」

---

## Phase 4 — Riverpod の DI をテストする（このプロジェクトの核）

### 学ぶこと
- **DI（依存性注入）**：クラスが必要とする部品を「外から渡す」設計。テスト時に本物→偽物に差し替えられる。
- Riverpod では `ProviderContainer(overrides: [...])` で Provider を偽物に差し替える。
- **Fake**：本物の代わりに使う、テスト用の軽い実装。

### このプロジェクトでなぜ重要か
ホワイトラベル設計の核が `brandConfigProvider` の override。
本番は `ItPassBrandConfig`、テストでは好きな値の Fake を注入できる。これが「Riverpod を選んだ理由」と直結する。

### テンプレート（これを写経する）
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        // brandConfigProvider.overrideWithValue(FakeBrandConfig()),
      ],
    );
    addTearDown(container.dispose); // リーク防止。必ず書く
  });

  test('provider が期待値を返す', () {
    // final value = container.read(someProvider);
    // expect(value, ...);
  });
}
```

### 手を動かす課題
- [ ] `FilterRepository` が `brandConfigProvider` のキーをプレフィックスに使うことを確認するテストを構想する
  - Fake で `analyticsBrandKey => 'test'` を返し、`filterRepositoryProvider` を read → prefix が `'test'` 由来になることを検証
- [ ] まずは構想をコメントで書き出す（実装は Phase 完走後でOK）

### 面接で話せること
> 「Riverpod の `ProviderContainer` の overrides で依存を差し替えられるので、テストが非常に書きやすいです。例えば BrandConfig を Fake に差し替えれば、ブランドごとに保存キーが分離される挙動を単体で検証できます。`addTearDown` で必ず container を破棄してリークを防いでいます。」

---

## Phase 5 — Widget テスト（画面を描画して検証）

### 学ぶこと
- `testWidgets('説明', (tester) async { ... })` … Widget 用のテスト。
- `tester.pumpWidget(...)` … Widget を描画。
- `find.text('...')` / `find.byIcon(...)` … 要素を探す。
- `tester.tap(...)` → `tester.pump()` … タップして再描画。

### リポジトリの実物
`packages/core/test/features/exam_quiz/quiz/view/widgets/choice_button_test.dart`。

```dart
testWidgets('正解を選択したとき正解アイコンが表示される', (tester) async {
  await tester.pumpWidget(/* QuizChoiceButton を MaterialApp で包む */);
  await tester.tap(find.text('選択肢A'));
  await tester.pump();
  expect(find.byIcon(Icons.check_circle), findsOneWidget);
});
```

### 手を動かす課題
- [ ] `choice_button_test.dart` を読み、「タップ→再描画→アイコン確認」の流れを説明できるようにする
- [ ] 「回答済みのときタップしてもコールバックが呼ばれない」テストがなぜ重要か言語化する（誤操作防止の仕様保証）

### 面接で話せること
> 「Widget テストでは Provider を Fake に差し替えてから `pumpWidget` で描画し、`find` で要素を探して `tap` で操作、`expect` で表示を検証します。選択肢ボタンでは、回答後にタップが無効化される仕様までテストでガードしています。」

---

## Phase 6 — カバレッジと CI を理解する

### 学ぶこと
- **カバレッジ** = テストがコードの何%を通過したか。100%が目的ではなく「重要ロジックが通っているか」が大事。
- CI（GitHub Actions）が毎 push でテストを自動実行している。

### リポジトリの実物
- `.github/workflows/ci.yml` … `flutter test --coverage` を実行し、`*.g.dart` / `*.freezed.dart`（自動生成ファイル）を除外してカバレッジを artifact 保存。

### コマンド
```bash
cd packages/core
flutter test --coverage          # coverage/lcov.info が生成される
```

### 手を動かす課題
- [ ] `.github/workflows/ci.yml` を読み、test ジョブと analyze ジョブの違いを説明する
- [ ] なぜ生成ファイル（`.g.dart`）をカバレッジから除外するのか考える（自分で書いていないコードだから）

### 面接で話せること
> 「CI で `flutter test --coverage` を回し、生成ファイルを除外したカバレッジを artifact として残しています。カバレッジは100%を狙うのではなく、出題アルゴリズムなどクリティカルなドメインロジックを優先的にカバーする方針です。」

---

## 仕上げ — 面接 想定 Q&A

| 質問 | 回答の骨子 |
|---|---|
| テストはなぜ書くの？ | リファクタの安全網・仕様書・手動確認の自動化 |
| 何をテストする？ | まず外部依存のない純粋なドメインロジック（出題順・習熟度）。次に Repository、ViewModel、主要 Widget |
| テストピラミッドとは？ | Unit を厚く、E2E を薄く。下ほど速く原因特定しやすいから |
| モックとは？ | 本物の依存（DB・通信）の代わりに使うテスト用実装。Fake を手書き、検証が要れば mocktail |
| Riverpod でどうテストする？ | `ProviderContainer(overrides:)` で Provider を差し替え。`addTearDown` で破棄 |
| テストの独立性は？ | `setUp` で毎回状態をリセット。テスト同士が順序に依存しないようにする |
| 時刻や乱数は？ | 引数で注入する設計にして再現性を確保（`DateTime.now()` を内部で呼ばない） |
| カバレッジの考え方は？ | 数値より「重要ロジックを通すこと」。生成ファイルは除外 |

---

## 進捗チェックリスト（全体）

- [x] Phase 0：テストの目的と用語3つを説明できた
- [x] Phase 1：`flutter test` を実行し、fail を体感した
- [x] Phase 2：純粋ロジックのテストを自分で1本追加した
- [x] Phase 3：非同期 + SharedPreferences モックのテストを追加した
- [ ] Phase 4：`ProviderContainer(overrides:)` のテンプレートを写経した
- [ ] Phase 5：Widget テストの流れを説明できた
- [ ] Phase 6：CI とカバレッジの役割を説明できた
- [ ] 仕上げ：Q&A を声に出して回答できた

---

## 次のステップ（このロードマップ完走後）

1. `QuizViewModel` の Unit テストを書く（最も実りが大きい。README「今後の改善」参照）
2. ↑のために `QuizViewModel` の Repository 直接 `new` を Provider 経由に直す（テスタビリティ改善）
3. カバレッジ閾値ゲートを CI に追加する
