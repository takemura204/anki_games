part of 'quiz_screen.dart';

// ---------------------------------------------------------------------------
// Answered action bar
// ---------------------------------------------------------------------------

class _AnsweredActionBar extends StatelessWidget {
  const _AnsweredActionBar({
    required this.onShowExplanation,
    required this.onNext,
  });

  final VoidCallback onShowExplanation;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onShowExplanation,
                  icon: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                  label: const Text(
                    '解説を見る',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white12),
              Expanded(
                child: TextButton.icon(
                  onPressed: onNext,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  label: const Text(
                    '次の問題へ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient background
// ---------------------------------------------------------------------------

class _QuizGradientBackground extends StatelessWidget {
  const _QuizGradientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0B2B),
            Color(0xFF1A0A3C),
            Color(0xFF2D1B69),
          ],
        ),
      ),
    );
  }
}
