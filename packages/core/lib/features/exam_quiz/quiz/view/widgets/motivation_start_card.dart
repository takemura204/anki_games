part of '../quiz_screen.dart';

class _MotivationStartCard extends StatefulWidget {
  const _MotivationStartCard({super.key, required this.quote});

  final Quote quote;

  @override
  State<_MotivationStartCard> createState() => _MotivationStartCardState();
}

class _MotivationStartCardState extends State<_MotivationStartCard>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _quoteCtrl;
  late final AnimationController _hintCtrl;

  late final Animation<double> _bgFade;
  late final Animation<Offset> _quoteSlide;
  late final Animation<double> _quoteFade;
  late final Animation<double> _hintFade;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _quoteCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut);
    _quoteSlide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _quoteCtrl, curve: Curves.easeOutCubic));
    _quoteFade = CurvedAnimation(parent: _quoteCtrl, curve: Curves.easeOut);
    _hintFade = CurvedAnimation(parent: _hintCtrl, curve: Curves.easeOut);

    _runEntrance();
  }

  Future<void> _runEntrance() async {
    _bgCtrl.forward().ignore();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _quoteCtrl.forward().ignore();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _hintCtrl.forward().ignore();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _quoteCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _bgFade,
      child: Column(
        children: [
          const Gap(AppSpacing.xxxl),
          const Spacer(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SlideTransition(
                position: _quoteSlide,
                child: FadeTransition(
                  opacity: _quoteFade,
                  child: _QuoteCard(quote: widget.quote),
                ),
              ),
            ),
          ),
          const Spacer(),
          FadeTransition(opacity: _hintFade, child: const _SwipeHint()),
          const Gap(AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassContainer(
      cardRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: ItPassColors.seed.withValues(alpha: 0.9),
            size: 40,
          ),
          const Gap(AppSpacing.sm),
          Text(
            quote.text,
            textAlign: TextAlign.center,
            style: AppTextStyle.titleLarge.copyWith(
              color: c.fg,
              height: 1.7,
              letterSpacing: 0.3,
              fontSize: 20,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            '— ${quote.author}',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMedium.copyWith(
              color: c.fgShade400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.keyboard_arrow_up_rounded, size: 45, color: c.fgShade300),
        Text(
          'スワイプして開始',
          style: AppTextStyle.bodyMedium.copyWith(
            color: c.fgShade400,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
