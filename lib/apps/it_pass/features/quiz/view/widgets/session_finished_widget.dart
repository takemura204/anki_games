part of '../quiz_screen.dart';

class _SetResultPage extends StatefulWidget {
  const _SetResultPage({
    super.key,
    required this.session,
    required this.elapsed,
    required this.onContinue,
  });

  final QuizSession session;
  final Duration elapsed;
  final VoidCallback onContinue;

  @override
  State<_SetResultPage> createState() => _SetResultPageState();
}

class _SetResultPageState extends State<_SetResultPage>
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
      curve: Curves.easeOut,
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
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
      padding: EdgeInsets.fromLTRB(16, top + 80, 16, bottom + 24),
      child: Column(
        children: [
          _buildCheckmark(correctCount, totalCount),
          const SizedBox(height: 28),
          FadeTransition(
            opacity: _contentFade,
            child: Column(
              children: [
                _buildScoreCard(correctCount, totalCount, rate, widget.elapsed),
                if (wrongAnswers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildWrongList(wrongAnswers),
                ],
                const SizedBox(height: 24),
                _buildContinueButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckmark(int correct, int total) {
    final isAllCorrect = correct == total && total > 0;
    final color =
        isAllCorrect ? const Color(0xFF10B981) : const Color(0xFF7C3AED);

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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(
                '$correct / $total 正解',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(
                    icon: Icons.percent_rounded,
                    label: '$rate%',
                    color: rate >= 80
                        ? const Color(0xFF10B981)
                        : rate >= 60
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(elapsed),
                    color: Colors.white54,
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
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              const Icon(
                Icons.cancel_outlined,
                color: Color(0xFFEF4444),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '不正解だった問題（${wrongAnswers.length}問）',
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...wrongAnswers.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '次の10問へ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WrongAnswerCard extends StatelessWidget {
  const _WrongAnswerCard({required this.result});

  final QuestionResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${result.question.no}. ${result.question.title}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _AnswerBadge(
                label: 'あなた: ${result.selectedLabel}',
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white24,
                size: 14,
              ),
              const SizedBox(width: 8),
              _AnswerBadge(
                label: '正解: ${result.question.answer}',
                color: const Color(0xFF10B981),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
