import 'package:core/features/exam_quiz/report/model/report_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportStats.formatCount', () {
    test('999 以下はカンマなしでそのまま返す', () {
      expect(ReportStats.formatCount(0), '0');
      expect(ReportStats.formatCount(999), '999');
    });

    test('1000 以上は「x,yyy」形式で返す', () {
      expect(ReportStats.formatCount(1000), '1,000');
      expect(ReportStats.formatCount(1234), '1,234');
      expect(ReportStats.formatCount(12000), '12,000');
    });
  });

  group('ReportStats.studyTimePrimary', () {
    test('1時間未満のとき分を返す', () {
      final r = ReportStats.studyTimePrimary(300);
      expect(r.value, '5');
      expect(r.unit, '分');
    });

    test('1時間以上のとき時間を返す', () {
      final r = ReportStats.studyTimePrimary(3661);
      expect(r.value, '1');
      expect(r.unit, '時間');
    });

    test('0秒のとき 0分 を返す', () {
      final r = ReportStats.studyTimePrimary(0);
      expect(r.value, '0');
      expect(r.unit, '分');
    });
  });

  group('ReportStats.studyTimeSecondary', () {
    test('1時間未満のとき null を返す', () {
      expect(ReportStats.studyTimeSecondary(3599), isNull);
    });

    test('1時間以上のとき残分を返す', () {
      final r = ReportStats.studyTimeSecondary(3720);
      expect(r, isNotNull);
      expect(r!.value, '2');
      expect(r.unit, '分');
    });
  });

  group('ReportStats.formatStudyTimeDelta', () {
    test('0秒のとき "0" を返す', () {
      expect(ReportStats.formatStudyTimeDelta(0), '0');
    });

    test('1時間未満のとき分のみを返す', () {
      expect(ReportStats.formatStudyTimeDelta(600), '10');
    });

    test('1時間以上のとき "x時間y" 形式を返す', () {
      expect(ReportStats.formatStudyTimeDelta(3720), '1時間2');
    });
  });
}
