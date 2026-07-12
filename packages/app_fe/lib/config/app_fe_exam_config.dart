import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/model/exam_meta.dart';

class AppFeExamConfig extends ExamConfig {
  const AppFeExamConfig();

  @override
  String get examTypeKey => 'fe';

  @override
  Set<String> get freeEraIds => const {
        'fe_r05_haru',
        'fe_r06_haru',
        'fe_r07_haru',
      };

  @override
  List<ExamMeta> get examList => const [
        ExamMeta(eraId: 'fe_r07_haru', displayName: '令和7年度', fileName: 'fe_r07_haru.json', group: ExamGroup.reiwa),
        ExamMeta(eraId: 'fe_r06_haru', displayName: '令和6年度', fileName: 'fe_r06_haru.json', group: ExamGroup.reiwa),
        ExamMeta(eraId: 'fe_r05_haru', displayName: '令和5年度', fileName: 'fe_r05_haru.json', group: ExamGroup.reiwa),
        ExamMeta(eraId: 'fe_r01_aki', displayName: '令和元年秋期', fileName: 'fe_r01_aki.json', group: ExamGroup.reiwa),
        ExamMeta(eraId: 'fe_h31_haru', displayName: '平成31年春期', fileName: 'fe_h31_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h30_aki', displayName: '平成30年秋期', fileName: 'fe_h30_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h30_haru', displayName: '平成30年春期', fileName: 'fe_h30_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h29_aki', displayName: '平成29年秋期', fileName: 'fe_h29_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h29_haru', displayName: '平成29年春期', fileName: 'fe_h29_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h28_aki', displayName: '平成28年秋期', fileName: 'fe_h28_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h28_haru', displayName: '平成28年春期', fileName: 'fe_h28_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h27_aki', displayName: '平成27年秋期', fileName: 'fe_h27_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h27_haru', displayName: '平成27年春期', fileName: 'fe_h27_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h26_aki', displayName: '平成26年秋期', fileName: 'fe_h26_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h26_haru', displayName: '平成26年春期', fileName: 'fe_h26_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h25_aki', displayName: '平成25年秋期', fileName: 'fe_h25_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h25_haru', displayName: '平成25年春期', fileName: 'fe_h25_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h24_aki', displayName: '平成24年秋期', fileName: 'fe_h24_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h24_haru', displayName: '平成24年春期', fileName: 'fe_h24_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h23_aki', displayName: '平成23年秋期', fileName: 'fe_h23_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h23_toku', displayName: '平成23年特別', fileName: 'fe_h23_toku.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h22_aki', displayName: '平成22年秋期', fileName: 'fe_h22_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h22_haru', displayName: '平成22年春期', fileName: 'fe_h22_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h21_aki', displayName: '平成21年秋期', fileName: 'fe_h21_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h21_haru', displayName: '平成21年春期', fileName: 'fe_h21_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h20_aki', displayName: '平成20年秋期', fileName: 'fe_h20_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h20_haru', displayName: '平成20年春期', fileName: 'fe_h20_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h19_aki', displayName: '平成19年秋期', fileName: 'fe_h19_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h19_haru', displayName: '平成19年春期', fileName: 'fe_h19_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h18_aki', displayName: '平成18年秋期', fileName: 'fe_h18_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h18_haru', displayName: '平成18年春期', fileName: 'fe_h18_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h17_aki', displayName: '平成17年秋期', fileName: 'fe_h17_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h17_haru', displayName: '平成17年春期', fileName: 'fe_h17_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h16_aki', displayName: '平成16年秋期', fileName: 'fe_h16_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h16_haru', displayName: '平成16年春期', fileName: 'fe_h16_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h15_aki', displayName: '平成15年秋期', fileName: 'fe_h15_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h15_haru', displayName: '平成15年春期', fileName: 'fe_h15_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h14_aki', displayName: '平成14年秋期', fileName: 'fe_h14_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h14_haru', displayName: '平成14年春期', fileName: 'fe_h14_haru.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h13_aki', displayName: '平成13年秋期', fileName: 'fe_h13_aki.json', group: ExamGroup.heisei),
        ExamMeta(eraId: 'fe_h13_haru', displayName: '平成13年春期', fileName: 'fe_h13_haru.json', group: ExamGroup.heisei),
      ];

  @override
  Map<String, List<String>> get categoryTree => const {
        'テクノロジ系': [
          '基礎理論',
          'アルゴリズムとプログラミング',
          'コンピュータ構成要素',
          'システム構成要素',
          'ソフトウェア',
          'ハードウェア',
          'ユーザーインタフェース',
          '情報メディア',
          'データベース',
          'ネットワーク',
          'セキュリティ',
          'システム開発技術',
          'ソフトウェア開発管理技術',
        ],
        'マネジメント系': [
          'プロジェクトマネジメント',
          'サービスマネジメント',
          'システム監査',
        ],
        'ストラテジ系': [
          'システム戦略',
          'システム企画',
          '経営戦略マネジメント',
          '技術戦略マネジメント',
          'ビジネスインダストリ',
          '企業活動',
          '法務',
        ],
        '科目B': [
          'アルゴリズムとプログラミング',
          '情報セキュリティ',
        ],
      };
}
