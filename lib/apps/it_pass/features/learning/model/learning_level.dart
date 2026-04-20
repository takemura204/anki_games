import 'package:anki_games/apps/it_pass/features/learning/model/question_learning_stats.dart';
import 'package:flutter/material.dart';

/// UI 用の学習レベル（5段階）。閾値は [fromStats] 先頭の定数で調整。
enum LearningLevel {
  unseen('未学習'),
  weak('苦手'),
  fuzzy('うろ覚え'),
  familiar('ほぼ覚えた'),
  mastered('覚えた');

  const LearningLevel(this.label);
  final String label;

  /// 試行回数がこれ以上かつ正答率が十分なとき「覚えた」
  static const _masteredMinAttempts = 4;

  /// 「覚えた」に必要な最低正答率
  static const _masteredMinAccuracy = 0.85;

  /// 「おぼ覚えた」に必要な最低正答率（未満は「うろ覚え」側）
  static const _familiarMinAccuracy = 0.65;

  static LearningLevel fromStats(QuestionLearningStats? stats) {
    if (stats == null) {
      return LearningLevel.unseen;
    }
    final total = stats.correctCount + stats.wrongCount;
    if (total == 0) {
      return LearningLevel.unseen;
    }
    final wrong = stats.wrongCount;
    final correct = stats.correctCount;
    if (wrong > correct) {
      return LearningLevel.weak;
    }
    final acc = correct / total;
    if (total >= _masteredMinAttempts &&
        acc >= _masteredMinAccuracy &&
        stats.lastWasCorrect == true) {
      return LearningLevel.mastered;
    }
    if (correct > wrong && acc >= _familiarMinAccuracy) {
      return LearningLevel.familiar;
    }
    return LearningLevel.fuzzy;
  }
}

extension LearningLevelPalette on LearningLevel {
  Color get filterForeground => switch (this) {
        LearningLevel.unseen => const Color(0xFF9CA3AF),
        LearningLevel.weak => const Color(0xFFFCA5A5),
        LearningLevel.fuzzy => const Color(0xFFFCD34D),
        LearningLevel.familiar => const Color(0xFF5EEAD4),
        LearningLevel.mastered => const Color(0xFF6EE7B7),
      };

  Color get filterBackground => switch (this) {
        LearningLevel.unseen =>
          const Color(0xFF9CA3AF).withValues(alpha: 0.2),
        LearningLevel.weak =>
          const Color(0xFFEF4444).withValues(alpha: 0.25),
        LearningLevel.fuzzy =>
          const Color(0xFFF59E0B).withValues(alpha: 0.22),
        LearningLevel.familiar =>
          const Color(0xFF14B8A6).withValues(alpha: 0.22),
        LearningLevel.mastered =>
          const Color(0xFF10B981).withValues(alpha: 0.22),
      };
}

Set<LearningLevel> parseLearningLevelsFromStorage(List<String>? raw) {
  if (raw == null || raw.isEmpty) {
    return {};
  }
  final out = <LearningLevel>{};
  for (final name in raw) {
    try {
      out.add(LearningLevel.values.byName(name));
    } on Object {
      // 未知の保存値は無視
    }
  }
  return out;
}
