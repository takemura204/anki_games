part of '../filter_sheet.dart';

class _MatchCountBar extends StatelessWidget {
  const _MatchCountBar({
    required this.matchCount,
    required this.canApply,
  });

  final int? matchCount;
  final bool canApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '該当',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        if (!canApply)
          Text(
            '—',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          )
        else if (matchCount == null)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          )
        else
          _AnimatedMatchCount(count: matchCount!),
        const SizedBox(width: 8),
        Text(
          '問',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AnimatedMatchCount extends StatefulWidget {
  const _AnimatedMatchCount({required this.count});

  final int count;

  @override
  State<_AnimatedMatchCount> createState() => _AnimatedMatchCountState();
}

class _AnimatedMatchCountState extends State<_AnimatedMatchCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var _increase = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..value = 1;
  }

  @override
  void didUpdateWidget(covariant _AnimatedMatchCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _increase = widget.count >= oldWidget.count;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ).value;
        final beginY = _increase ? 14.0 : -14.0;
        final dy = beginY * (1 - t);
        final scale = 0.88 + 0.12 * t;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: 0.2 + 0.8 * t,
              child: Text(
                '${widget.count}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
