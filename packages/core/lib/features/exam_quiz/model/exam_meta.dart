import 'package:flutter/foundation.dart';

enum ExamGroup { heisei, reiwa, sample }

class ExamMeta {
  const ExamMeta({
    required this.eraId,
    required this.displayName,
    required this.assetPath,
    required this.group,
  });

  final String eraId;
  final String displayName;

  /// 旧バンドルパス。ローカルキャッシュのファイル名導出に使用。
  /// 例: `'packages/app_it_pass/assets/quiz/it_pass_r07.json'`
  final String assetPath;
  final ExamGroup group;

  bool get isSample => group == ExamGroup.sample;

  bool isFree(Set<String> freeEraIds) =>
      !kReleaseMode || freeEraIds.contains(eraId);

  /// Documents/quiz/{examTypeKey}/{fileName} で使うファイル名。
  String get fileName => assetPath.split('/').last;
}
