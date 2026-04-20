part of '../quiz_screen.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.cardRadius,
    required this.session,
    required this.onUserPressed,
    required this.onFilterPressed,
    this.centerLabel,
  });

  final BorderRadius cardRadius;
  final QuizSession session;
  final VoidCallback onUserPressed;
  final VoidCallback onFilterPressed;

  /// null のときは「現在/全問」の進捗を表示する
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: top + 12,
        bottom: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.person_outline,
                color: Colors.white70,
                size: 22,
              ),
              onPressed: onUserPressed,
            ),
          ),
          _GlassContainer(
            cardRadius: cardRadius,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            width: 140,
            child: centerLabel != null
                ? Center(
                    child: Text(
                      centerLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${session.indexInSet + 1}/${session.totalCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              end: session.totalCount > 0
                                  ? (session.indexInSet + 1) /
                                      session.totalCount
                                  : 0,
                            ),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white70,
                                ),
                                minHeight: 8,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          _GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              iconSize: 22,
              padding: EdgeInsets.zero,
              color: Colors.white70,
              icon: const Icon(Icons.tune_outlined),
              onPressed: onFilterPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.cardRadius, required this.child});

  final BorderRadius cardRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.cardRadius,
    required this.child,
    this.padding,
    this.width,
  });

  final BorderRadius cardRadius;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: child,
        ),
      ),
    );
  }
}
