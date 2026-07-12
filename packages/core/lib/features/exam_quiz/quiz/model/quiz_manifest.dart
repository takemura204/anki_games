import 'package:flutter/foundation.dart';

/// Firebase Hosting から取得するクイズデータのマニフェスト。
@immutable
class QuizManifest {
  const QuizManifest({
    required this.schemaVersion,
    required this.generatedAt,
    required this.exams,
  });

  factory QuizManifest.fromJson(Map<String, dynamic> json) {
    final examsJson = json['exams'] as Map<String, dynamic>? ?? {};
    return QuizManifest(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      generatedAt: json['generatedAt'] as String? ?? '',
      exams: examsJson.map(
        (key, value) => MapEntry(
          key,
          ExamManifest.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  final int schemaVersion;
  final String generatedAt;

  /// examTypeKey → 試験マニフェスト
  final Map<String, ExamManifest> exams;
}

@immutable
class ExamManifest {
  const ExamManifest({required this.version, required this.files});

  factory ExamManifest.fromJson(Map<String, dynamic> json) {
    final filesList = json['files'] as List<dynamic>? ?? [];
    return ExamManifest(
      version: json['version'] as String? ?? '',
      files: filesList
          .map((e) => QuizFileEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String version;
  final List<QuizFileEntry> files;
}

@immutable
class QuizFileEntry {
  const QuizFileEntry({
    required this.name,
    required this.sha256,
    required this.sizeBytes,
    required this.path,
  });

  factory QuizFileEntry.fromJson(Map<String, dynamic> json) {
    return QuizFileEntry(
      name: json['name'] as String,
      sha256: json['sha256'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      path: json['path'] as String,
    );
  }

  final String name;
  final String sha256;
  final int sizeBytes;

  /// CDN 上の相対パス（例: quiz/it_pass/it_pass_r07.json）
  final String path;
}
