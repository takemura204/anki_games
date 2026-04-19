part of '../quiz_screen.dart';

class _ExplanationBottomSheet extends StatefulWidget {
  const _ExplanationBottomSheet({
    required this.sheetController,
    required this.slideAnimation,
    required this.question,
    required this.isLast,
    required this.onNext,
    required this.onDismiss,
  });

  final AnimationController sheetController;
  final Animation<Offset> slideAnimation;
  final Question question;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onDismiss;

  @override
  State<_ExplanationBottomSheet> createState() =>
      _ExplanationBottomSheetState();
}

class _ExplanationBottomSheetState extends State<_ExplanationBottomSheet> {
  var _dragStartY = 0.0;

  void _onPanStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dy = details.globalPosition.dy - _dragStartY;
    if (dy > 0) {
      final sheetHeight = MediaQuery.of(context).size.height * 0.65;
      final normalized = 1.0 - (dy / sheetHeight).clamp(0.0, 1.0);
      widget.sheetController.value = normalized;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -500) {
      widget.onNext();
    } else if (velocity > 400 || widget.sheetController.value < 0.5) {
      widget.onDismiss();
    } else {
      widget.sheetController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SlideTransition(
        position: widget.slideAnimation,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.65),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F12).withValues(alpha: 0.94),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDragHandle(),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 12),
                                Text(
                                  widget.question.explanationText,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.75,
                                  ),
                                ),
                                if (widget.question.explanationImages
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ...widget.question.explanationImages.map(
                                    (url) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: _QuizNetworkImage(url: url),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNextButton(),
                              if (!widget.isLast) _buildSwipeHint(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.lightbulb_outline_rounded,
          color: Color(0xFF10B981),
          size: 18,
        ),
        const SizedBox(width: 8),
        const Text(
          '解説',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        const _AudioWaveformWidget(),
        const SizedBox(width: 12),
        Text(
          '正解: ${widget.question.answer}',
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: widget.onNext,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isLast ? '結果を見る' : '次の問題へ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.isLast
                    ? Icons.flag_rounded
                    : Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeHint() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Center(
        child: Text(
          '↑ 上にスワイプでも次へ',
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
      ),
    );
  }
}

class _AudioWaveformWidget extends StatefulWidget {
  const _AudioWaveformWidget();

  @override
  State<_AudioWaveformWidget> createState() => _AudioWaveformWidgetState();
}

class _AudioWaveformWidgetState extends State<_AudioWaveformWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _barControllers;
  late final List<Animation<double>> _barAnimations;

  static const _barCount = 4;
  static const _delays = [0, 120, 60, 180];

  @override
  void initState() {
    super.initState();
    _barControllers = List.generate(
      _barCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _barAnimations = _barControllers.map((c) {
      return Tween<double>(begin: 0.3, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (var i = 0; i < _barCount; i++) {
      Future.delayed(Duration(milliseconds: _delays[i]), () {
        if (mounted) {
          _barControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _barControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_barCount, (i) {
          return AnimatedBuilder(
            animation: _barAnimations[i],
            builder: (context, _) {
              return Container(
                width: 3,
                height: 18 * _barAnimations[i].value,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
