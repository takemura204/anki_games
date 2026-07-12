import 'package:core/config/styles/app_colors.dart';
import 'package:flutter/material.dart';

import 'leitner_box.dart';
import 'question_learning_stats.dart';

/// UI 用の学習レベル（5段階）。箱番号と1:1で対応する。
enum LearningLevel {
  unseen('未学習'),
  weak('苦手'),
  fuzzy('うろ覚え'),
  familiar('得意'),
  mastered('完璧');

  const LearningLevel(this.label);
  final String label;

  /// Leitner ボックス番号からレベルを導出する。
  static LearningLevel fromBox(int box) => switch (box) {
    1 => LearningLevel.weak,
    2 => LearningLevel.fuzzy,
    3 => LearningLevel.familiar,
    _ => LearningLevel.mastered,
  };

  /// stats からレベルを導出する（box フィールド未設定時は旧データ推定）。
  static LearningLevel fromStats(QuestionLearningStats? stats) {
    if (stats == null) return LearningLevel.unseen;
    final total = stats.correctCount + stats.wrongCount;
    if (total == 0) return LearningLevel.unseen;
    return fromBox(resolvedBox(stats));
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
