part of '../quiz_screen.dart';

class _ExplanationSheet extends StatefulWidget {
  const _ExplanationSheet({
    required this.sheetController,
    required this.slideAnimation,
    required this.question,
    required this.selectedLabel,
    required this.isLast,
    required this.onNext,
    required this.onDismiss,
  });

  final AnimationController sheetController;
  final Animation<Offset> slideAnimation;
  final Question question;
  final String selectedLabel;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onDismiss;

  @override
  State<_ExplanationSheet> createState() => _ExplanationSheetState();
}

class _ExplanationSheetState extends State<_ExplanationSheet> {
  var _dragStartY = 0.0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
            bottom: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.55),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D0B2B),
                        Color(0xFF1A0A3C),
                        Color(0xFF2D1B69),
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDragHandle(),
                      Flexible(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const Gap(12),
                                Row(
                                  children: [
                                    _buildAnswerChip(
                                      label: '正解',
                                      value: widget.question.answer,
                                      valueColor: const Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildAnswerChip(
                                      label: 'あなた',
                                      value: widget.selectedLabel,
                                      valueColor: widget.selectedLabel ==
                                              widget.question.answer
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ],
                                ),
                                const Gap(12),
                                Text(
                                  widget.question.explanationText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.75,
                                  ),
                                ),
                                if (widget
                                    .question.explanationImages.isNotEmpty) ...[
                                  const Gap(12),
                                  ...widget.question.explanationImages
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: _QuizNetworkImage(
                                            url: e.value,
                                            heroTag: 'img_q'
                                                '${widget.question.no}'
                                                '_exp_${e.key}',
                                          ),
                                        ),
                                      ),
                                ],
                                const Gap(15),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Created by Gimini',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 9,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: _buildNextButton(),
                      ),
                    ],
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
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        const Text(
          '解説',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(AppUrls.contact),
            mode: LaunchMode.externalApplication,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag_outlined,
                color: Colors.white54,
                size: 14,
              ),
              Gap(3),
              Text(
                '誤りを報告',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerChip({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: valueColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: valueColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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
}
