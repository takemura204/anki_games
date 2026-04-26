import 'dart:ui';

import 'package:app_it_pass/features/learning/model/learning_level.dart';
import 'package:app_it_pass/features/quiz/model/question.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'quiz_network_image.dart';

// ignore: always_use_package_imports
import '../../../../config/theme/it_pass_color_scheme.dart';

class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
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
                hasImages ? AppSpacing.sm : AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: hasImages
                    ? const BorderRadius.vertical(top: Radius.circular(radius))
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
                                color: c.fgShade50,
                                borderRadius: AppBorderRadius.full,
                              ),
                              child: Text(
                                question.major.isNotEmpty
                                    ? '${question.system} » ${question.major}'
                                    : question.system,
                                style: AppTextStyle.labelSmall.copyWith(
                                  color: c.fgShade400,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.normal,
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
                          (e) => QuizNetworkImage(
                            url: e.value,
                            heroTag: 'img_q${question.no}_body_${e.key}',
                          ),
                        ),
                  ],
                  const Gap(AppSpacing.sm),
                  Row(
                    children: [
                      LearningLevelBadge(level: learningLevel),
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

class LearningLevelBadge extends StatelessWidget {
  const LearningLevelBadge({super.key, required this.level});

  final LearningLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: level.colorBg,
        borderRadius: AppBorderRadius.full,
        border: Border.all(
          color: level.colorFg.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        level.label,
        style: AppTextStyle.labelSmall.copyWith(
          color: level.colorFg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
