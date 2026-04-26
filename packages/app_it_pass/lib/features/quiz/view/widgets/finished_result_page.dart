part of '../quiz_screen.dart';

class _FinishResultPage extends ConsumerStatefulWidget {
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
  ConsumerState<_FinishResultPage> createState() => _FinishResultPageState();
}

class _FinishResultPageState extends ConsumerState<_FinishResultPage>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkProgress;
  late final AnimationController _contentController;
  late final Animation<double> _contentFade;
  int _todayCount = 0;

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
    _loadTodayCount();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayCount() async {
    final records = await LocalQuizHistoryRepository().loadRecent(limit: 1000);
    final today = DateTime.now();
    final count = records.where((r) {
      return r.answeredAt.year == today.year &&
          r.answeredAt.month == today.month &&
          r.answeredAt.day == today.day;
    }).length;
    if (mounted) setState(() => _todayCount = count);
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m == 0 ? s.toString() : m.toString();
  }

  static String _formatDurationUnit(Duration d) {
    final m = d.inMinutes;
    return m == 0 ? '秒' : '分';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final session = widget.session;
    final correctCount = session.setCorrectCount;
    final totalCount = session.currentSetAnswers.length;
    final rate = totalCount > 0 ? (correctCount / totalCount * 100).round() : 0;
    final allAnswers = session.currentSetAnswers;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        top + AppSpacing.xxl + AppSpacing.sm,
        AppSpacing.md,
        bottom + AppSpacing.lg,
      ),
      child: Column(
        children: [
          _Checkmark(
            correct: correctCount,
            total: totalCount,
            progress: _checkProgress,
          ),
          const Gap(28),
          FadeTransition(
            opacity: _contentFade,
            child: Column(
              children: [
                _ScoreCard(
                  correctCount: correctCount,
                  totalCount: totalCount,
                  rate: rate,
                  elapsed: widget.elapsed,
                  todayCount: _todayCount,
                  formatDuration: _formatDuration,
                  formatDurationUnit: _formatDurationUnit,
                ),
                if (allAnswers.isNotEmpty) ...[
                  const Gap(AppSpacing.md),
                  _AnswerList(answers: allAnswers),
                ],
                const Gap(AppSpacing.lg),
                _ContinueButton(
                  hasNext: session.hasNextSet,
                  onContinue: widget.onContinue,
                ),
              ],
            ),
          ),
          const Gap(50),
        ],
      ),
    );
  }
}

class _Checkmark extends StatelessWidget {
  const _Checkmark({
    required this.correct,
    required this.total,
    required this.progress,
  });

  final int correct;
  final int total;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final isAllCorrect = correct == total && total > 0;
    final color = isAllCorrect ? AppColors.success : AppColors.itPassSeed;

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) => SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: _CheckmarkPainter(
            progress: progress.value,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.correctCount,
    required this.totalCount,
    required this.rate,
    required this.elapsed,
    required this.todayCount,
    required this.formatDuration,
    required this.formatDurationUnit,
  });

  final int correctCount;
  final int totalCount;
  final int rate;
  final Duration elapsed;
  final int todayCount;
  final String Function(Duration) formatDuration;
  final String Function(Duration) formatDurationUnit;
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(color: c.border1),
          ),
          child: Column(
            children: [
              _StatItem(
                name: '正答率',
                value: rate == 100 ? '全問正解！' : '$correctCount',
                unit: '/$totalCount',
                valueLarge: true,
              ),
              const Gap(AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      name: '解答時間',
                      value: formatDuration(elapsed),
                      unit: formatDurationUnit(elapsed),
                    ),
                  ),
                  Container(width: 1, height: 48, color: c.border1),
                  Expanded(
                    child: _StatItem(
                      name: '本日の累計',
                      value: '$todayCount',
                      unit: '問',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.name,
    required this.value,
    required this.unit,
    this.valueLarge = false,
  });

  final String name;
  final String value;
  final String unit;
  final bool valueLarge;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatChip(label: name),
        const Gap(AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyle.headlineMedium.copyWith(
                color: c.fg,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              unit,
              style: AppTextStyle.bodyMedium.copyWith(
                color: c.fgShade400,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnswerList extends StatelessWidget {
  const _AnswerList({required this.answers});

  final List<QuestionResult> answers;

  @override
  Widget build(BuildContext context) {
    final wrongAnswers = answers.where((r) => !r.isCorrect).toList();
    final correctAnswers = answers.where((r) => r.isCorrect).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wrongAnswers.isNotEmpty) ...[
          _SectionHeader(
            icon: AppIcons.incorrect,
            color: AppColors.error,
            label: '不正解(${wrongAnswers.length}問)',
          ),
          const Gap(AppSpacing.xs + 2),
          ...wrongAnswers.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _QuizAnswerCard(
                    result: e.value,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ResultDetailSheet(
                        results: wrongAnswers,
                        initialIndex: e.key,
                      ),
                    ),
                  ),
                ),
              ),
        ],
        if (wrongAnswers.isNotEmpty && correctAnswers.isNotEmpty)
          const Gap(AppSpacing.md),
        if (correctAnswers.isNotEmpty) ...[
          _SectionHeader(
            icon: AppIcons.correct,
            color: AppColors.success,
            label: '正解(${correctAnswers.length}問)',
          ),
          const Gap(AppSpacing.xs + 2),
          ...correctAnswers.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _QuizAnswerCard(
                    result: e.value,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ResultDetailSheet(
                        results: correctAnswers,
                        initialIndex: e.key,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.hasNext,
    required this.onContinue,
  });

  final bool hasNext;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final label = hasNext ? '次のクイズへ' : '完了';
    final icon =
        hasNext ? Icons.keyboard_arrow_up_rounded : Icons.check_rounded;

    return GestureDetector(
      onTap: onContinue,
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
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const Gap(AppSpacing.sm),
              Icon(icon, color: Colors.white, size: AppSpacing.md + 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizAnswerCard extends ConsumerWidget {
  const _QuizAnswerCard({required this.result, required this.onTap});

  final QuestionResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = result.question;
    final storageKey = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);

    final liveBookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => const <String>{},
    };
    final isBookmarked = liveBookmarks.contains(storageKey);

    final statsMap = switch (ref.watch(itPassLearningStatsProvider)) {
      AsyncData(:final value) => value,
      _ => const <String, QuestionLearningStats>{},
    };
    final level = LearningLevel.fromStats(statsMap[storageKey]);

    final c = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: AppBorderRadius.md,
          border: Border.all(color: c.border1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              result.isCorrect ? AppIcons.correct : AppIcons.incorrect,
              size: 16,
              color: result.isCorrect ? AppColors.success : AppColors.error,
            ),
            const Gap(AppSpacing.xs),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${q.no}.',
                    style: AppTextStyle.labelLarge.copyWith(
                      color: c.fg,
                      height: 1.3,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  Expanded(
                    child: Text(
                      q.title,
                      style: AppTextStyle.labelLarge.copyWith(
                        color: c.fg,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.xs),
            LearningLevelBadge(level: level),
            const Gap(AppSpacing.xs),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(bookmarkProvider.notifier).toggle(q.eraId, q.no),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isBookmarked ? AppIcons.bookmarked : AppIcons.bookmark,
                  color: isBookmarked ? AppColors.itPassSeed : c.fgShade200,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = c.fgShade300;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppBorderRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyle.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
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
            Icons.emoji_events_outlined,
            size: AppSpacing.xxl + AppSpacing.sm,
            color: AppColors.warning,
          ),
          const Gap(AppSpacing.md + 4),
          Text(
            '全問完了！',
            textAlign: TextAlign.center,
            style: AppTextStyle.headlineSmall.copyWith(
              color: context.appColors.fg,
            ),
          ),
          const Gap(12),
          Text(
            'すべての問題を解き終えました。\n出題範囲を変えて新たな問題に挑戦しましょう。',
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
