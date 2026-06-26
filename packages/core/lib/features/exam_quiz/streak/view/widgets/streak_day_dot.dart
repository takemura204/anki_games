part of '../streak_banner.dart';

class _StreakDayDot extends StatelessWidget {
  const _StreakDayDot({
    required this.label,
    required this.status,
    this.animateCheck = false,
  });

  final String label;
  final DayStatus status;
  final bool animateCheck;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyle.captionSmall.copyWith(
            color: context.appColors.fgShade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(AppSpacing.xs),
        _Dot(status: status, animateCheck: animateCheck),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.status, this.animateCheck = false});

  final DayStatus status;
  final bool animateCheck;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  static const _size = 26.0;
  static const _dotColor = Color(0xFF9B6EF5);

  bool get _shouldAnimate =>
      widget.status == DayStatus.studied && widget.animateCheck;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: AppAnimation.decelerate,
    );

    if (_shouldAnimate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_Dot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasAnimating =
        oldWidget.status == DayStatus.studied && oldWidget.animateCheck;
    if (!wasAnimating && _shouldAnimate) {
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
    return switch (widget.status) {
      DayStatus.studied => _buildStudied(),
      DayStatus.frozen => _frozenDot,
      DayStatus.missed => _missedDot,
      DayStatus.notYet => _notYetDot,
    };
  }

  Widget _buildStudied() {
    // アニメーション不要な場合は progress=1.0 で直接描画し、
    // AnimationController の初期化タイミングに依存しない。
    if (!widget.animateCheck) {
      return const SizedBox(
        width: _size,
        height: _size,
        child: CustomPaint(
          painter: CheckmarkPainter(
            progress: 1,
            color: _dotColor,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, _) => SizedBox(
        width: _size,
        height: _size,
        child: CustomPaint(
          painter: CheckmarkPainter(
            progress: _progress.value,
            color: _dotColor,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget get _frozenDot => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.15),
      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
    ),
    child: const Center(
      child: Icon(Icons.ac_unit, size: 14, color: Colors.white70),
    ),
  );

  Widget get _missedDot => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.08),
    ),
  );

  Widget get _notYetDot => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.08),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    ),
  );
}
