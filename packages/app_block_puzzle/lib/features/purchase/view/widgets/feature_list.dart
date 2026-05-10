part of '../paywall_sheet.dart';

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.c});
  final ItPassColorScheme c;

  static const _features = [
    (Icons.quiz_rounded, '1日の問題数', '無制限'),
    (Icons.history_edu_rounded, '過去問', '全年度解放'),
    (Icons.block_rounded, '広告', '非表示'),
    (Icons.sync_rounded, 'アカウント同期', '可能'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      cardRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < _features.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(_features[i].$1, size: 20, color: c.fg),
                  const Gap(12),
                  Text(
                    _features[i].$2,
                    style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
                  ),
                  const Spacer(),
                  Text(
                    _features[i].$3,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.fg,
                    ),
                  ),
                ],
              ),
            ),
            if (i < _features.length - 1)
              Divider(height: 1, indent: 14, endIndent: 14, color: c.fgShade50),
          ],
        ],
      ),
    );
  }
}
