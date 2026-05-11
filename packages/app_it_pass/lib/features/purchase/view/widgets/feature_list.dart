part of '../paywall_sheet.dart';

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.c});
  final ItPassColorScheme c;

  static const _features = [
    (Icons.block_outlined, '広告', '非表示'),
    (Icons.auto_stories_outlined, '学習範囲', '全問解放'),
    (Icons.school_outlined, '1日の学習数', '無制限'),
    (Icons.sync_outlined, 'データ同期', '自動更新'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: GlassContainer(
        cardRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < _features.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(_features[i].$1, size: 20, color: c.fgShade400),
                    const Gap(AppSpacing.sm),
                    Text(
                      _features[i].$2,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: c.fg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _features[i].$3,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: c.fg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < _features.length - 1)
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: c.fgShade50,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
