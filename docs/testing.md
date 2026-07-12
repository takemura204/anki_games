# テスト戦略

> 最終更新: 2026-06-24

---

## 方針：テストピラミッド

```
              ╱▲╲
             ╱    ╲         Integration (E2E): ~10%
            ╱──────╲        Maestro / Patrol（将来対応）
           ╱          ╲
          ╱────────────╲    Widget: ~20%
         ╱ Widget Tests  ╲   主要画面の表示・インタラクション
        ╱──────────────────╲
       ╱   Unit Tests        ╲  ~70%
      ╱ コアドメインロジック    ╲  QuizQuestionOrdering / LearningLevel / Streak
     ╱────────────────────────╲
```

土台をしっかり Unit テストで固め、その上に Widget テスト・E2E を積む。Unit テストなしで E2E を追加しても「なぜ落ちたか」の切り分けができないため、この順序を守る。

---

## Unit テスト

### 方針

- **テスト対象**: ビジネスロジック（Model / Repository のピュアロジック）。Flutter SDK に依存しない部分を優先。
- **モック**: `mocktail`（コード生成不要・null 安全）を採用。ただし単純な依存差し替えは **手書き Fake** を優先し、呼び出し回数の検証が必要な場合のみ `mocktail` の `Mock` クラスを使う。
- **Riverpod**: `ProviderContainer` を直接生成し `overrides` で差し替え。`addTearDown(container.dispose)` を必ず書いてリーク防止。

### テンプレート（Riverpod + Fake）

```dart
void main() {
  group('QuizViewModel', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          quizRepositoryProvider.overrideWithValue(FakeQuizRepository()),
        ],
      );
      addTearDown(container.dispose);
    });

    test('出題リストが空のとき QuizError を返す', () async {
      final state = await container.read(quizViewModelProvider.future);
      expect(state, isA<QuizError>());
    });
  });
}
```

### テンプレート（純粋ロジック）

```dart
// ProviderContainer 不要。普通のクラスとして呼び出す。
void main() {
  group('LearningLevel.fromStats', () {
    test('null のとき unseen を返す', () {
      expect(LearningLevel.fromStats(null), LearningLevel.unseen);
    });

    test('誤答 > 正答のとき weak を返す', () {
      final stats = QuestionLearningStats(correctCount: 1, wrongCount: 3);
      expect(LearningLevel.fromStats(stats), LearningLevel.weak);
    });
  });
}
```

### 対象クラス一覧（優先度順）

| # | クラス | ファイル | テスト観点 |
|---|---|---|---|
| 1 | `QuizQuestionOrdering` | `quiz/repository/quiz_question_ordering.dart` | モード別順序・優先度スコア境界値・未学習ブースト |
| 2 | `LearningLevel.fromStats` | `learning/model/learning_level.dart` | 5分岐すべて（null / total=0 / weak / familiar / mastered） |
| 3 | `QuestionLearningStats` | `learning/model/question_learning_stats.dart` | fromJson / toJson ラウンドトリップ / copyWith |
| 4 | `LocalStreakRepository.recordStudy` | `streak/repository/local_streak_repository.dart` | 連続 / 途切れ / フリーズ消費 / 同日重複 |
| 5 | `ReportStats` 集計 | `report/view_model/report_stats_provider.dart` | 累計・日次配列長・正答率計算 |

---

## Widget テスト

### 方針

- `ProviderScope(overrides: [...])` で Repository を Fake に差し替えてからウィジェットをポンプする。
- `tester.pumpAndSettle()` で非同期解決を待つ。
- `find.text('...')` / `find.byType(...)` で表示確認、`tester.tap(...)` でインタラクション確認。

### テンプレート

```dart
testWidgets('正解時に正解マークが表示される', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quizViewModelProvider.overrideWith(() => FakeQuizViewModel()),
      ],
      child: const MaterialApp(home: QuizScreen()),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('選択肢A'));
  await tester.pumpAndSettle();

  expect(find.byIcon(Icons.check_circle), findsOneWidget);
});
```

### 対象画面一覧

| # | 画面 | テスト観点 |
|---|---|---|
| 1 | `QuizScreen` | 選択肢タップ→正誤フィードバック表示 |
| 2 | `FinishedResultPage` | 正答率・解答数の数値表示 |
| 3 | `ReportSheet` | グラフ・統計値の表示（Fake データ） |

---

## カバレッジ

```bash
# カバレッジ計測（生成ファイルを除外）
flutter test --coverage -C packages/core
lcov --remove coverage/lcov.info '*.g.dart' '*.freezed.dart' -o coverage/lcov_clean.info
genhtml coverage/lcov_clean.info -o coverage/html
```

CI では `lcov` の結果をアーティファクトとして保存し、カバレッジ率が閾値を下回った場合にビルドを失敗させる（目標: コアドメイン 80% 以上）。

---

## Integration テスト（将来対応）

Phase C（2026-07 末以降）で以下の1〜2動線を Maestro または Patrol で自動化する予定。

- 起動 → クイズ1問回答 → 正誤確認 → 次の問題
- オンボーディング通過フロー

Maestro: YAML ベース・ゼロ依存（APK/IPA に直接）で導入コストが低い。ただし複雑なアニメーション待ちは Patrol（gray-box）のほうが安定。採用時に改めて比較検討する。

---

## CI でのテスト実行（Phase A-3 で追加予定）

現在の `.github/workflows/ci.yml` は `flutter analyze` のみ。以下を追加する。

```yaml
- name: Run tests with coverage
  working-directory: packages/core
  run: flutter test --coverage

- name: Remove generated files from lcov
  run: |
    lcov --remove coverage/lcov.info '**/*.g.dart' '**/*.freezed.dart' \
         -o coverage/lcov_clean.info

- name: Upload coverage artifact
  uses: actions/upload-artifact@v4
  with:
    name: coverage-report
    path: packages/core/coverage/lcov_clean.info
```
