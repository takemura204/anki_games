part of '../quiz_screen.dart';

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.learningLevel,
  });

  final Question question;
  final LearningLevel learningLevel;

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
    final cardRadius = BorderRadius.circular(radius);
    final hasImages = question.body.images.isNotEmpty;

    final c = context.appColors;

    return ClipRRect(
      borderRadius: cardRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: cardRadius,
          border: Border.all(color: c.border1),
          color: c.surface2,
        ),
        child: ClipRRect(
          borderRadius: hasImages
              ? const BorderRadius.vertical(top: Radius.circular(radius))
              : cardRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                hasImages ? 12 : AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: hasImages
                    ? const BorderRadius.vertical(
                        top: Radius.circular(radius),
                      )
                    : cardRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (question.categoryRaw.isNotEmpty)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: c.fgShade100,
                                borderRadius: AppBorderRadius.full,
                              ),
                              child: Text(
                                question.major.isNotEmpty
                                    ? '${question.system} » ${question.major}'
                                    : question.system,
                                style: AppTextStyle.labelSmall.copyWith(
                                  color: Colors.white60,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                    ],
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    question.body.text,
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: c.fg,
                      height: 1.6,
                    ),
                  ),
                  if (question.body.subItems.isNotEmpty) ...[
                    const Gap(AppSpacing.sm),
                    ...question.body.subItems.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs + 2,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${String.fromCharCode(97 + e.key)}. ',
                                  style: AppTextStyle.bodySmall
                                      .copyWith(color: c.fg),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: AppTextStyle.bodySmall.copyWith(
                                      color: c.fg,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                  if (hasImages) ...[
                    const Gap(AppSpacing.sm),
                    ...question.body.images.asMap().entries.map(
                          (e) => _QuizNetworkImage(
                            url: e.value,
                            heroTag: 'img_q${question.no}_body_${e.key}',
                          ),
                        ),
                  ],
                  const Gap(AppSpacing.sm),
                  Row(
                    children: [
                      _LearningLevelBadge(level: learningLevel),
                      const Spacer(),
                      if (question.examDisplayName.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${question.examDisplayName} 問${question.no}',
                            style: AppTextStyle.labelLarge.copyWith(
                              color: c.fgShade300,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningLevelBadge extends StatelessWidget {
  const _LearningLevelBadge({required this.level});

  final LearningLevel level;

  @override
  Widget build(BuildContext context) {
    final (:fg, :bg) = switch (level) {
      LearningLevel.unseen => (
          fg: const Color(0xFF9CA3AF),
          bg: const Color(0xFF9CA3AF).withValues(alpha: 0.2),
        ),
      LearningLevel.weak => (
          fg: const Color(0xFFFCA5A5),
          bg: AppColors.error.withValues(alpha: 0.25),
        ),
      LearningLevel.fuzzy => (
          fg: const Color(0xFFFCD34D),
          bg: AppColors.warning.withValues(alpha: 0.22),
        ),
      LearningLevel.familiar => (
          fg: const Color(0xFF5EEAD4),
          bg: const Color(0xFF14B8A6).withValues(alpha: 0.22),
        ),
      LearningLevel.mastered => (
          fg: const Color(0xFF6EE7B7),
          bg: AppColors.success.withValues(alpha: 0.22),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorderRadius.full,
        border: Border.all(
          color: fg.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        level.label,
        style: AppTextStyle.labelSmall.copyWith(
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
