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
  final String assetPath;
  final ExamGroup group;

  static const _base = 'packages/app_it_pass/assets/quiz';

  static const all = [
    ExamMeta(eraId: 'h21_aki', displayName: '平成21年秋期', assetPath: '$_base/it_pass_h21_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h21_haru', displayName: '平成21年春期', assetPath: '$_base/it_pass_h21_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h22_aki', displayName: '平成22年秋期', assetPath: '$_base/it_pass_h22_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h22_haru', displayName: '平成22年春期', assetPath: '$_base/it_pass_h22_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h23_aki', displayName: '平成23年秋期', assetPath: '$_base/it_pass_h23_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h23_toku', displayName: '平成23年特別', assetPath: '$_base/it_pass_h23_toku.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h24_aki', displayName: '平成24年秋期', assetPath: '$_base/it_pass_h24_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h24_haru', displayName: '平成24年春期', assetPath: '$_base/it_pass_h24_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h25_aki', displayName: '平成25年秋期', assetPath: '$_base/it_pass_h25_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h25_haru', displayName: '平成25年春期', assetPath: '$_base/it_pass_h25_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h26_aki', displayName: '平成26年秋期', assetPath: '$_base/it_pass_h26_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h26_haru', displayName: '平成26年春期', assetPath: '$_base/it_pass_h26_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h27_aki', displayName: '平成27年秋期', assetPath: '$_base/it_pass_h27_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h27_haru', displayName: '平成27年春期', assetPath: '$_base/it_pass_h27_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h28_aki', displayName: '平成28年秋期', assetPath: '$_base/it_pass_h28_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h28_haru', displayName: '平成28年春期', assetPath: '$_base/it_pass_h28_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h29_aki', displayName: '平成29年秋期', assetPath: '$_base/it_pass_h29_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h29_haru', displayName: '平成29年春期', assetPath: '$_base/it_pass_h29_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h30_aki', displayName: '平成30年秋期', assetPath: '$_base/it_pass_h30_aki.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h30_haru', displayName: '平成30年春期', assetPath: '$_base/it_pass_h30_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'h31_haru', displayName: '平成31年春期', assetPath: '$_base/it_pass_h31_haru.json', group: ExamGroup.heisei),
    ExamMeta(eraId: 'r01_aki', displayName: '令和元年秋期', assetPath: '$_base/it_pass_r01_aki.json', group: ExamGroup.reiwa),
    ExamMeta(eraId: 'r02_aki', displayName: '令和2年秋期', assetPath: '$_base/it_pass_r02_aki.json', group: ExamGroup.reiwa),
    ExamMeta(eraId: 'r03', displayName: '令和3年', assetPath: '$_base/it_pass_r03.json', group: ExamGroup.reiwa),
    ExamMeta(eraId: 'r04', displayName: '令和4年', assetPath: '$_base/it_pass_r04.json', group: ExamGroup.reiwa),
    ExamMeta(eraId: 'r05', displayName: '令和5年', assetPath: '$_base/it_pass_r05.json', group: ExamGroup.reiwa),
    ExamMeta(eraId: 'r06', displayName: '令和6年', assetPath: '$_base/it_pass_r06.json', group: ExamGroup.reiwa),
    ExamMeta(eraId: 'r07', displayName: '令和7年', assetPath: '$_base/it_pass_r07.json', group: ExamGroup.reiwa),
    ExamMeta(eraId: 'sample1', displayName: 'サンプル問題①', assetPath: '$_base/it_pass_sample1.json', group: ExamGroup.sample),
    ExamMeta(eraId: 'sample2', displayName: 'サンプル問題②', assetPath: '$_base/it_pass_sample2.json', group: ExamGroup.sample),
  ];

  static const categoryTree = {
    'ストラテジ系': [
      '企業活動',
      '法務',
      '経営戦略マネジメント',
      '技術戦略マネジメント',
      'ビジネスインダストリ',
      'システム戦略',
      'システム企画',
    ],
    'マネジメント系': [
      'プロジェクトマネジメント',
      'サービスマネジメント',
      'システム開発技術',
      'ソフトウェア開発管理技術',
      'システム監査',
    ],
    'テクノロジ系': [
      '基礎理論',
      'アルゴリズムとプログラミング',
      'コンピュータ構成要素',
      'システム構成要素',
      'ソフトウェア',
      'ハードウェア',
      'ヒューマンインタフェース',
      '情報デザイン',
      'マルチメディア',
      'データベース',
      'ネットワーク',
      'セキュリティ',
    ],
  };
}
