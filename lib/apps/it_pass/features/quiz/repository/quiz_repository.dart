import 'dart:convert';
import 'dart:math';

import 'package:anki_games/apps/it_pass/features/quiz/model/exam_meta.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/question.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/quiz_filter.dart';
import 'package:flutter/services.dart';

class QuizRepository {
  static const _sessionSize = 10;

  Future<List<Question>> loadSession(QuizFilter filter) async {
    final all = <Question>[];

    for (final meta in ExamMeta.all) {
      if (!filter.selectedEraIds.contains(meta.eraId)) {
        continue;
      }
      final raw = await rootBundle.loadString(meta.assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final questions = (json['questions'] as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
      all.addAll(questions);
    }

    final filtered = all.where((q) {
      if (filter.selectedSystems.isNotEmpty &&
          !filter.selectedSystems.contains(q.system)) {
        return false;
      }
      if (filter.selectedMajors.isNotEmpty &&
          !filter.selectedMajors.contains(q.major)) {
        return false;
      }
      return true;
    }).toList()
      ..shuffle(Random());

    return filtered.take(_sessionSize).toList();
  }
}
