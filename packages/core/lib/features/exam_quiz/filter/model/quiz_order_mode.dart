enum QuizOrderMode {
  /// ExamMeta の定義順 → 各試験内は問題番号昇順
  sequential,

  /// 一様ランダム（従来どおり）
  random,

  /// 学習履歴に基づく重み付き順（試験対策向け）
  optimized,
}

extension QuizOrderModeStorage on QuizOrderMode {
  static QuizOrderMode fromStorage(String? raw) {
    return QuizOrderMode.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => QuizOrderMode.optimized,
    );
  }
}
