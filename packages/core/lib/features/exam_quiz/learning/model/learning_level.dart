import 'package:core/config/styles/app_colors.dart';
import 'package:flutter/material.dart';

import 'question_learning_stats.dart';

/// UI 用の学習レベル（5段階）。閾値は [fromStats] 先頭の定数で調整。
enum LearningLevel {
  unseen('未学習'),
  weak('苦手'),
  fuzzy('うろ覚え'),
  familiar('得意'),
  mastered('完璧');

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
  Color get colorFg => switch (this) {
    LearningLevel.unseen => AppColors.learningLevelUnseen,
    LearningLevel.weak => AppColors.learningLevelWeak,
    LearningLevel.fuzzy => AppColors.learningLevelFuzzy,
    LearningLevel.familiar => AppColors.learningLevelFamiliar,
    LearningLevel.mastered => AppColors.learningLevelMastered,
  };

  Color get colorBg => switch (this) {
    LearningLevel.unseen => const Color(0xFF9CA3AF).withValues(alpha: 0.22),
    LearningLevel.weak => AppColors.learningLevelWeak.withValues(alpha: 0.22),
    LearningLevel.fuzzy => AppColors.learningLevelFuzzy.withValues(alpha: 0.22),
    LearningLevel.familiar => AppColors.learningLevelFamiliar.withValues(
      alpha: 0.22,
    ),
    LearningLevel.mastered => AppColors.learningLevelMastered.withValues(
      alpha: 0.22,
    ),
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
