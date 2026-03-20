import 'package:flutter/services.dart';
import 'package:mono_games/features/quiz/model/quiz_word.dart';

/// `assets/quiz/words.csv` を読み込み [QuizWord] リストを返すデータソース。
class CsvWordDatasource {
  /// CSV ファイルを読み込み、全単語を返す。
  Future<List<QuizWord>> load() async {
    final raw = await rootBundle.loadString('assets/quiz/words.csv');
    final lines = raw.trim().split('\n');
    // ヘッダー行をスキップ
    return lines.skip(1).map(_parseLine).whereType<QuizWord>().toList();
  }

  QuizWord? _parseLine(String line) {
    final parts = line.split(',');
    if (parts.length < 4) {
      return null;
    }
    final id = int.tryParse(parts[0].trim());
    if (id == null) {
      return null;
    }
    return QuizWord(
      id: id,
      en: parts[1].trim(),
      ja: parts[2].trim(),
      category: parts[3].trim(),
    );
  }
}
