import 'question_learning_stats.dart';

/// Leitner ボックス番号の範囲（1〜4）。
const kLeitnerMinBox = 1;
const kLeitnerMaxBox = 4;

/// 各ボックスの復習間隔（日数）。
/// box1=苦手(当日再出題), box2=うろ覚え(翌日), box3=得意(3日後), box4=完璧(7日後)
const _kBoxIntervalDays = [0, 1, 3, 7];

/// 正解で箱を +1 し、不正解で box1 へリセットする。
/// 未学習(currentBox==null)からは 正解→box2 / 不正解→box1。
int advance(int? currentBox, {required bool isCorrect}) {
  if (!isCorrect) return kLeitnerMinBox;
  if (currentBox == null) return kLeitnerMinBox + 1;
  return (currentBox + 1).clamp(kLeitnerMinBox, kLeitnerMaxBox);
}

/// ボックスに対応する復習間隔日数を返す。
int intervalDaysForBox(int box) {
  final idx = box.clamp(kLeitnerMinBox, kLeitnerMaxBox) - 1;
  return _kBoxIntervalDays[idx];
}

/// 次回の復習期限（due）を返す。
DateTime dueAt(int box, DateTime lastAnsweredAt) {
  return lastAnsweredAt.add(Duration(days: intervalDaysForBox(box)));
}

/// 復習期限が到来しているかを判定する。
bool isDue(int box, DateTime lastAnsweredAt, {required DateTime now}) {
  return !now.isBefore(dueAt(box, lastAnsweredAt));
}

/// box フィールドが存在しない旧データから初期箱番号を推定する。
/// LearningLevel の旧ロジックと同等の分類を Leitner 箱に対応させる。
int boxFromLegacyStats(QuestionLearningStats stats) {
  final total = stats.correctCount + stats.wrongCount;
  if (total == 0) return kLeitnerMinBox;

  final correct = stats.correctCount;
  final wrong = stats.wrongCount;

  if (wrong > correct) return kLeitnerMinBox; // 苦手

  final acc = correct / total;
  if (total >= 4 && acc >= 0.85 && stats.lastWasCorrect == true) {
    return kLeitnerMaxBox; // 完璧
  }
  if (correct > wrong && acc >= 0.65) return 3; // 得意
  return 2; // うろ覚え
}

/// stats から有効な box 番号を取得する。
/// box フィールドが null の場合は旧データから推定する。
int resolvedBox(QuestionLearningStats stats) {
  if (stats.box != null) return stats.box!;
  return boxFromLegacyStats(stats);
}
