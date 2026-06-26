import 'package:core/components/glass_widget.dart';
import 'package:core/components/quiz_network_image.dart';
import 'package:core/config/brand/it_pass_color_scheme.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/model/question.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

/// 回答後に表示するインライン解説カード。
///
/// [showExtras] を true にすると誤り報告リンクを表示する（クイズ本編用）。
/// Native 広告はカード外（呼び出し元）に配置する。
class ExplanationCard extends StatelessWidget {
  const ExplanationCard({
    super.key,
    required this.question,
    required this.selectedLabel,
    this.showExtras = false,
  });

  final Question question;
  final String selectedLabel;
  final bool showExtras;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isCorrect = selectedLabel == question.answer;

    return GlassContainer(
      cardRadius: AppBorderRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.explanation, size: 18, color: c.fgShade400),
              const Gap(AppSpacing.xs),
              Text(
                '解説',
                style: AppTextStyle.labelLarge.copyWith(
                  color: c.fgShade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Row(
            children: [
              _AnswerChip(
                label: '正解',
                value: question.answer,
                valueColor: AppColors.success,
              ),
              const Gap(12),
              _AnswerChip(
                label: 'あなた',
                value: selectedLabel,
                valueColor: isCorrect ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          if (question.explanationChoiceComments.isNotEmpty) ...[
            const Gap(AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: AppBorderRadius.sm,
              ),
              child: Column(
                children: [
                  ...question.explanationChoiceComments.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${String.fromCharCode(97 + e.key)}. ',
                            style: AppTextStyle.bodyMedium.copyWith(
                              color: c.fg,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: AppTextStyle.bodyMedium.copyWith(
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
              ),
            ),
          ],
          const Gap(AppSpacing.sm),
          Text(
            question.explanationText,
            style: AppTextStyle.bodyLarge.copyWith(color: c.fg, height: 1.75),
          ),
          if (question.explanationImages.isNotEmpty) ...[
            const Gap(AppSpacing.sm),
            ...question.explanationImages.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: QuizNetworkImage(
                  url: e.value,
                  heroTag: 'img_q${question.no}_exp_${e.key}',
                ),
              ),
            ),
          ],
          if (showExtras) ...[
            const Gap(AppSpacing.md),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(AppUrls.contact),
                mode: LaunchMode.externalApplication,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.flag, color: c.fgShade300, size: 14),
                  const Gap(3),
                  Text(
                    '誤りを報告',
                    style: AppTextStyle.labelSmall.copyWith(
                      color: c.fgShade300,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Created by Gimini',
                    style: AppTextStyle.captionSmall.copyWith(
                      color: c.fgShade300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 正解時に折りたたみ状態で表示するコンパクトカード。
/// [onExpand] をタップするとフル解説に切り替える。
class CollapsedExplanationCard extends StatelessWidget {
  const CollapsedExplanationCard({super.key, required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassContainer(
      cardRadius: AppBorderRadius.md,
      child: InkWell(
        onTap: onExpand,
        borderRadius: AppBorderRadius.md,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(AppIcons.explanation, size: 16, color: c.fgShade400),
              const Gap(AppSpacing.xs),
              Text(
                '解説を見る',
                style: AppTextStyle.labelMedium.copyWith(
                  color: c.fgShade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: c.fgShade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: valueColor.withValues(alpha: 0.10),
        borderRadius: AppBorderRadius.sm,
        border: Border.all(color: valueColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: AppTextStyle.titleSmall.copyWith(
                color: valueColor,
                letterSpacing: 0,
              ),
            ),
            Text(
              value,
              style: AppTextStyle.titleSmall.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}
