import 'package:core/features/exam_quiz/streak/repository/local_streak_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStreakRepository.recordStudy', () {
    final repo = LocalStreakRepository();

    test('初回学習でストリークが 1 になる', () async {
      final today = DateTime(2026, 6);
      final result = await repo.recordStudy(today);

      expect(result.currentStreak, 1);
      expect(result.lastStudiedDate, '2026-06-01');
    });

    test('同日に 2 回呼ぶとストリークが増えない', () async {
      final today = DateTime(2026, 6);
      await repo.recordStudy(today);
      final result = await repo.recordStudy(today);

      expect(result.currentStreak, 1);
    });

    test('連続した日はストリークが加算される', () async {
      await repo.recordStudy(DateTime(2026, 6));
      await repo.recordStudy(DateTime(2026, 6, 2));
      final result = await repo.recordStudy(DateTime(2026, 6, 3));

      expect(result.currentStreak, 3);
    });

    test('フリーズが 0 の状態で 1 日飛ばすとストリークがリセットされて 1 になる', () async {
      // まず 6/1 に学習してフリーズを消費させる（6/1→6/3 でフリーズ消費 → freezeCount=0）
      await repo.recordStudy(DateTime(2026, 6));
      await repo.recordStudy(DateTime(2026, 6, 3)); // freezeCount: 1→0
      // 今度は 6/4 に学習後、6/6（2日空き）で試す
      await repo.recordStudy(DateTime(2026, 6, 4));
      final result = await repo.recordStudy(DateTime(2026, 6, 6));

      expect(result.currentStreak, 1);
    });

    test('フリーズが残っていれば 2 日空いてもストリークが継続する', () async {
      // freezeCount のデフォルトは 1
      await repo.recordStudy(DateTime(2026, 6));
      // 6/2 を飛ばして 6/3 に学習
      final result = await repo.recordStudy(DateTime(2026, 6, 3));

      expect(result.currentStreak, 2);
      expect(result.freezeCount, 0);
      expect(result.frozenDates, contains('2026-06-02'));
    });

    test('フリーズが 0 のとき 2 日空くとストリークがリセットされる', () async {
      // まず一度フリーズを消費する
      await repo.recordStudy(DateTime(2026, 6));
      await repo.recordStudy(DateTime(2026, 6, 3)); // フリーズ消費 → freezeCount=0
      // さらに 2 日空かす
      final result = await repo.recordStudy(DateTime(2026, 6, 6));

      expect(result.currentStreak, 1);
    });

    test('studiedDates に今日の日付が追加される', () async {
      final today = DateTime(2026, 6);
      final result = await repo.recordStudy(today);

      expect(result.studiedDates, contains('2026-06-01'));
    });

    test('showBanner が true になる', () async {
      final result = await repo.recordStudy(DateTime(2026, 6));
      expect(result.showBanner, isTrue);
    });
  });
}
