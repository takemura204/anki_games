import 'package:anki_games/common/features/quiz/model/quiz_word.dart';
import 'package:flutter/services.dart';

/// 英検レベル別 CSV ファイルを読み込み [QuizWord] リストを返すデータソース。
///
/// 各 CSV のローカル ID が重複するため、レベルごとにプレフィックスを加算して
/// グローバル一意 ID を生成する。
/// - eiken5:    100001〜
/// - eiken4:    200001〜
/// - eiken3:    300001〜
/// - eiken2pre: 400001〜
/// - eiken2:    500001〜
/// - debug:     990001〜
class CsvWordDatasource {
  static const List<({String path, int idOffset})> _sources = [
    (path: 'assets/quiz/eiken5.csv', idOffset: 100000),
    (path: 'assets/quiz/eiken4.csv', idOffset: 200000),
    (path: 'assets/quiz/eiken3.csv', idOffset: 300000),
    (path: 'assets/quiz/eiken2pre.csv', idOffset: 400000),
    (path: 'assets/quiz/eiken2.csv', idOffset: 500000),
    (path: 'assets/quiz/toeic600.csv', idOffset: 600000),
    (path: 'assets/quiz/toeic700.csv', idOffset: 700000),
    (path: 'assets/quiz/toeic800.csv', idOffset: 800000),
    (path: 'assets/quiz/toeic900.csv', idOffset: 900000),
    (path: 'assets/quiz/debug.csv', idOffset: 990000),
  ];

  /// 全 CSV ファイルを読み込み、全単語を返す。
  Future<List<QuizWord>> load() async {
    final results = <QuizWord>[];
    for (final source in _sources) {
      final raw = await rootBundle.loadString(source.path);
      final lines = raw.trim().split('\n');
      for (final line in lines.skip(1)) {
        final word = _parseLine(line, source.idOffset);
        if (word != null) {
          results.add(word);
        }
      }
    }
    return results;
  }

  QuizWord? _parseLine(String line, int idOffset) {
    final parts = line.split(',');
    if (parts.length < 7) {
      return null;
    }
    final localId = int.tryParse(parts[0].trim());
    if (localId == null) {
      return null;
    }
    return QuizWord(
      id: idOffset + localId,
      en: parts[1].trim(),
      ja: parts[2].trim(),
      pos: parts[3].trim(),
      theme: parts[4].trim(),
      level: parts[5].trim(),
      isFrequent: parts[6].trim() == '1',
    );
  }
}
