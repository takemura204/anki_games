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
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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

    if (!isAnswered) {
      borderColor = Colors.white.withValues(alpha: 0.2);
      bgColor = Colors.white.withValues(alpha: 0.05);
      textColor = Colors.white;
      glowShadows = [];
    } else if (isCorrect) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.18);
      textColor = Colors.white;
      glowShadows = [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.55),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ];
    } else if (isSelected) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.18);
      textColor = Colors.white;
      glowShadows = [
        BoxShadow(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
          blurRadius: 16,
        ),
      ];
    } else {
      borderColor = Colors.white.withValues(alpha: 0.08);
      bgColor = Colors.white.withValues(alpha: 0.02);
      textColor = Colors.white38;
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
            borderRadius: BorderRadius.circular(14),
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
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.choice.label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (hasText) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.choice.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (isAnswered && isCorrect)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  if (isAnswered && isSelected && !isCorrect)
                    const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                ],
              ),
              if (hasImage) ...[
                const SizedBox(height: 8),
                ...widget.choice.images.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _QuizNetworkImage(
                      url: e.value,
                      heroTag: 'img_q${widget.session.currentQuestion.no}'
                          '_choice_${widget.choice.label}_${e.key}',
                      borderRadius: BorderRadius.circular(8),
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
