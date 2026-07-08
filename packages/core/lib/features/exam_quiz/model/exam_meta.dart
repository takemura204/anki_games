import 'package:flutter/foundation.dart';

enum ExamGroup { heisei, reiwa, sample }

class ExamMeta {
  const ExamMeta({
    required this.eraId,
    required this.displayName,
    required this.fileName,
    required this.group,
  });

  final String eraId;
  final String displayName;

  /// Documents/quiz/{examTypeKey}/{fileName} で使うファイル名（例: 'it_pass_r07.json'）。
  final String fileName;
  final ExamGroup group;

  bool get isSample => group == ExamGroup.sample;

  bool isFree(Set<String> freeEraIds) =>
      !kReleaseMode || freeEraIds.contains(eraId);
}
