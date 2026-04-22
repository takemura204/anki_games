part of '../quiz_screen.dart';

class _ChoiceButton extends StatefulWidget {
  const _ChoiceButton({
    required this.choice,
    required this.session,
    required this.onTap,
  });

  final QuestionChoice choice;
  final QuizSession session;
  final VoidCallback onTap;

  @override
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120), // タップフィードバックのチューニング値
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: AppAnimation.standard,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.session.isAnswered) {
      return;
    }
    await _pulseController.forward();
    await _pulseController.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.session.selectedLabel == widget.choice.label;
    final isCorrect =
        widget.choice.label == widget.session.currentQuestion.answer;
    final isAnswered = widget.session.isAnswered;
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
      textColor = Colors.white; // 色付き背景上なので常に白
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
      textColor = Colors.white; // 色付き背景上なので常に白
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
          duration: const Duration(milliseconds: 320), // 選択状態変化のチューニング値
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
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                  if (isAnswered && isSelected && !isCorrect)
                    const Icon(
                      Icons.cancel_rounded,
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
                        child: _QuizNetworkImage(
                          url: e.value,
                          heroTag: 'img_q${widget.session.currentQuestion.no}'
                              '_choice_${widget.choice.label}_${e.key}',
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
