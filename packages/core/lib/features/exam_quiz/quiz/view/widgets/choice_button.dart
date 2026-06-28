import 'package:core/components/quiz_network_image.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/model/question.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class QuizChoiceButton extends StatefulWidget {
  const QuizChoiceButton({
    super.key,
    required this.choice,
    required this.questionNo,
    required this.correctLabel,
    required this.isAnswered,
    this.selectedLabel,
    this.onTap,
  });

  final QuestionChoice choice;

  /// 画像の Hero タグ生成に使用する問題番号
  final int questionNo;

  /// 正解の選択肢ラベル
  final String correctLabel;

  /// 回答済みか（true のとき色付きハイライトを表示）
  final bool isAnswered;

  /// 現在選択中のラベル（null = 未選択）
  final String? selectedLabel;

  /// タップコールバック。null または [isAnswered] が true のときはタップ不可。
  final VoidCallback? onTap;

  @override
  State<QuizChoiceButton> createState() => _QuizChoiceButtonState();
}

class _QuizChoiceButtonState extends State<QuizChoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _pulseController, curve: AppAnimation.standard),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.isAnswered || widget.onTap == null) return;
    Haptics.light().ignore();
    await _pulseController.forward();
    await _pulseController.reverse();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedLabel == widget.choice.label;
    final isCorrect = widget.choice.label == widget.correctLabel;
    final isAnswered = widget.isAnswered;
    final hasImage = widget.choice.images.isNotEmpty;
    final hasText = widget.choice.text.isNotEmpty;

    final Color borderColor;
    final Color bgColor;
    final Color textColor;
    final List<BoxShadow> glowShadows;

    final c = context.appColors;

    if (!isAnswered) {
      borderColor = c.border2;
      bgColor = c.surface1;
      textColor = c.fg;
      glowShadows = [];
    } else if (isCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.18);
      textColor = Colors.white;
      glowShadows = [
        BoxShadow(
          color: AppColors.success.withValues(alpha: 0.55),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ];
    } else if (isSelected) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.18);
      textColor = Colors.white;
      glowShadows = [
        BoxShadow(
          color: AppColors.error.withValues(alpha: 0.4),
          blurRadius: AppSpacing.md,
        ),
      ];
    } else {
      borderColor = c.surface2;
      bgColor = c.surface1;
      textColor = c.fgShade200;
      glowShadows = [];
    }

    return GestureDetector(
      onTap: isAnswered ? null : _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppBorderRadius.md,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: glowShadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.appColors.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.choice.label,
                        style: AppTextStyle.titleSmall.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (hasText) ...[
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.choice.text,
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (isAnswered && isCorrect)
                    const Icon(
                      AppIcons.correct,
                      color: AppColors.success,
                      size: 20,
                    )
                  else if (isAnswered && isSelected && !isCorrect)
                    const Icon(
                      AppIcons.incorrect,
                      color: AppColors.error,
                      size: 20,
                    ),
                ],
              ),
              if (hasImage) ...[
                const Gap(AppSpacing.sm),
                ...widget.choice.images.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: QuizNetworkImage(
                      url: e.value,
                      heroTag:
                          'img_q${widget.questionNo}_choice_${widget.choice.label}_${e.key}',
                      borderRadius: AppBorderRadius.sm,
                      tapToView: false,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
