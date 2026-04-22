part of '../quiz_screen.dart';

class _FinishResultPage extends StatefulWidget {
  const _FinishResultPage({
    super.key,
    required this.session,
    required this.elapsed,
    required this.onContinue,
  });

  final QuizSession session;
  final Duration elapsed;
  final VoidCallback onContinue;

  @override
  State<_FinishResultPage> createState() => _FinishResultPageState();
}

class _FinishResultPageState extends State<_FinishResultPage>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkProgress;
  late final AnimationController _contentController;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _checkProgress = CurvedAnimation(
      parent: _checkController,
      curve: AppAnimation.decelerate,
    );

    _contentController = AnimationController(
      vsync: this,
      duration: AppAnimation.slow,
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: AppAnimation.decelerate,
    );

    _checkController.forward().then((_) => _contentController.forward());
  }

  @override
  void dispose() {
    _checkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m == 0) {
      return '$s秒';
    }
    return '$m分${s.toString().padLeft(2, '0')}秒';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final session = widget.session;
    final correctCount = session.setCorrectCount;
    final totalCount = session.currentSetAnswers.length;
    final rate = totalCount > 0 ? (correctCount / totalCount * 100).round() : 0;
    final wrongAnswers = session.setWrongAnswers;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        top + AppSpacing.xxl + AppSpacing.sm,
        AppSpacing.md,
        bottom + AppSpacing.lg,
      ),
      child: Column(
        children: [
          _buildCheckmark(correctCount, totalCount),
          const Gap(28),
          FadeTransition(
            opacity: _contentFade,
            child: Column(
              children: [
                _buildScoreCard(correctCount, totalCount, rate, widget.elapsed),
                if (wrongAnswers.isNotEmpty) ...[
                  const Gap(AppSpacing.md + 4),
                  _buildWrongList(wrongAnswers),
                ],
                const Gap(AppSpacing.lg),
                _buildContinueButton(),
              ],
            ),
          ),
          const Gap(50),
        ],
      ),
    );
  }

  Widget _buildCheckmark(int correct, int total) {
    final isAllCorrect = correct == total && total > 0;
    final color = isAllCorrect ? AppColors.success : AppColors.itPassSeed;

    return AnimatedBuilder(
      animation: _checkProgress,
      builder: (context, _) {
        return SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _CheckmarkPainter(
              progress: _checkProgress.value,
              color: color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCard(int correct, int total, int rate, Duration elapsed) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.appColors.surface2,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(color: context.appColors.border1),
          ),
          child: Column(
            children: [
              Text(
                rate == 100 ? '全問正解！' : '$correct / $total 正解',
                style: AppTextStyle.displaySmall.copyWith(
                  color: rate == 100 ? AppColors.success : context.appColors.fg,
                  letterSpacing: 1,
                ),
              ),
              const Gap(AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(
                    icon: Icons.percent_rounded,
                    label: '$rate%',
                    color: rate >= 80
                        ? AppColors.success
                        : rate >= 60
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                  const Gap(12),
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(elapsed),
                    color: context.appColors.fgShade300,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWrongList(List<QuestionResult> wrongAnswers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 10),
          child: Row(
            children: [
              const Icon(
                Icons.cancel_outlined,
                color: AppColors.error,
                size: AppSpacing.md,
              ),
              const Gap(AppSpacing.xs + 2),
              Text(
                '不正解だった問題（${wrongAnswers.length}問）',
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...wrongAnswers.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _WrongAnswerCard(result: r),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: widget.onContinue,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.itPassSeed, AppColors.itPassAccent],
          ),
          borderRadius: AppBorderRadius.lg,
          boxShadow: [
            BoxShadow(
              color: AppColors.itPassSeed.withValues(alpha: 0.4),
              blurRadius: AppSpacing.md + 4,
              offset: const Offset(0, AppSpacing.xs + 2),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '次へ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              Gap(AppSpacing.sm),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: AppSpacing.md + 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionEndPage extends StatelessWidget {
  const _SessionEndPage({
    super.key,
    required this.onOpenFilter,
  });

  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        top + AppSpacing.xxl + AppSpacing.sm,
        AppSpacing.md,
        bottom + AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.filter_alt_outlined,
            size: AppSpacing.xxl + AppSpacing.sm,
            color: context.appColors.fgShade400,
          ),
          const Gap(AppSpacing.md + 4),
          Text(
            'このセットは完了しました',
            textAlign: TextAlign.center,
            style: AppTextStyle.headlineSmall.copyWith(
              color: context.appColors.fg,
            ),
          ),
          const Gap(12),
          Text(
            '出題範囲を選び直すと、新しいセット（最大10問）で再開できます。',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMedium.copyWith(
              color: context.appColors.fgShade400,
              height: 1.5,
            ),
          ),
          const Gap(AppSpacing.xl + 4),
          GestureDetector(
            onTap: onOpenFilter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.itPassSeed, AppColors.itPassAccent],
                ),
                borderRadius: AppBorderRadius.lg,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.itPassSeed.withValues(alpha: 0.4),
                    blurRadius: AppSpacing.md + 4,
                    offset: const Offset(0, AppSpacing.xs + 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  Gap(10),
                  Text(
                    '出題範囲を選び直す',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppBorderRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const Gap(AppSpacing.xs + 2),
          Text(
            label,
            style: AppTextStyle.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WrongAnswerCard extends StatefulWidget {
  const _WrongAnswerCard({required this.result});

  final QuestionResult result;

  @override
  State<_WrongAnswerCard> createState() => _WrongAnswerCardState();
}

class _WrongAnswerCardState extends State<_WrongAnswerCard> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final q = widget.result.question;
    final c = context.appColors;
    final bgAlpha = _expanded ? 0.04 : 0.08;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: bgAlpha),
        borderRadius: AppBorderRadius.md,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ヘッダー行（常時表示） ──
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Q${q.no}. ${q.title}',
                          style: AppTextStyle.labelLarge.copyWith(
                            color: c.fgShade400,
                            height: 1.4,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(AppSpacing.xs),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: c.fgShade200,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.xs + 2),
                  Row(
                    children: [
                      _AnswerBadge(
                        label: 'あなた: ${widget.result.selectedLabel}',
                        color: AppColors.error,
                      ),
                      const Gap(AppSpacing.sm),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: c.fgShade100,
                        size: 14,
                      ),
                      const Gap(AppSpacing.sm),
                      _AnswerBadge(
                        label: '正解: ${q.answer}',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── 展開コンテンツ ──
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 問題文
                            if (q.body.text.isNotEmpty) ...[
                              Text(
                                q.body.text,
                                style: AppTextStyle.bodySmall.copyWith(
                                  color: c.fgShade300,
                                  height: 1.6,
                                ),
                              ),
                              const Gap(AppSpacing.sm),
                            ],

                            // 解説テキスト
                            if (q.explanationText.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: AppColors.warning,
                                    size: 14,
                                  ),
                                  const Gap(4),
                                  Text(
                                    '解説',
                                    style: AppTextStyle.labelSmall.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(6),
                              Text(
                                q.explanationText,
                                style: AppTextStyle.bodySmall.copyWith(
                                  color: c.fgShade400,
                                  height: 1.6,
                                ),
                              ),
                            ],

                            // 選択肢コメント
                            if (q.explanationChoiceComments.isNotEmpty) ...[
                              const Gap(AppSpacing.sm),
                              ...List.generate(
                                q.explanationChoiceComments.length,
                                (i) {
                                  final comment =
                                      q.explanationChoiceComments[i];
                                  if (comment.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  final choiceLabel = i < q.choices.length
                                      ? q.choices[i].label
                                      : '${i + 1}';
                                  final isCorrect = choiceLabel == q.answer;
                                  final isSelected = choiceLabel ==
                                      widget.result.selectedLabel;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isCorrect
                                                ? AppColors.success
                                                    .withValues(alpha: 0.15)
                                                : isSelected
                                                    ? AppColors.error
                                                        .withValues(alpha: 0.15)
                                                    : c.fgShade50
                                                        .withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            choiceLabel,
                                            style: AppTextStyle.labelSmall
                                                .copyWith(
                                              color: isCorrect
                                                  ? AppColors.success
                                                  : isSelected
                                                      ? AppColors.error
                                                      : c.fgShade200,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Gap(8),
                                        Expanded(
                                          child: Text(
                                            comment,
                                            style:
                                                AppTextStyle.bodySmall.copyWith(
                                              color: c.fgShade300,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AnswerBadge extends StatelessWidget {
  const _AnswerBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: AppBorderRadius.sm -
            const BorderRadius.all(
              Radius.circular(2),
            ),
      ),
      child: Text(
        label,
        style: AppTextStyle.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    final arcProgress = (progress * 1.4).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * arcProgress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0.5) {
      final checkProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final startPoint = Offset(size.width * 0.24, size.height * 0.5);
      final midPoint = Offset(size.width * 0.44, size.height * 0.68);
      final endPoint = Offset(size.width * 0.76, size.height * 0.33);

      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      if (checkProgress < 0.5) {
        final t = checkProgress * 2;
        final current = Offset.lerp(startPoint, midPoint, t)!;
        path
          ..moveTo(startPoint.dx, startPoint.dy)
          ..lineTo(current.dx, current.dy);
      } else {
        final t = (checkProgress - 0.5) * 2;
        final current = Offset.lerp(midPoint, endPoint, t)!;
        path
          ..moveTo(startPoint.dx, startPoint.dy)
          ..lineTo(midPoint.dx, midPoint.dy)
          ..lineTo(current.dx, current.dy);
      }
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) => old.progress != progress;
}
