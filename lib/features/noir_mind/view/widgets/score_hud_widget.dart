import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/noir_mind/model/game_theme.dart';
import 'package:mono_games/features/noir_mind/view_model/noir_mind_view_model.dart';

/// スコア・ハイスコア・コンボを表示するHUD。
class ScoreHudWidget extends ConsumerStatefulWidget {
  /// スコアHUDウィジェットを作成する。
  const ScoreHudWidget({required this.theme, super.key});

  /// 現在のゲームテーマ。
  final GameTheme theme;

  @override
  ConsumerState<ScoreHudWidget> createState() => _ScoreHudWidgetState();
}

class _ScoreHudWidgetState extends ConsumerState<ScoreHudWidget>
    with TickerProviderStateMixin {
  int _displayScore = 0;
  late final AnimationController _scoreController;
  late final AnimationController _comboController;
  late final Animation<double> _comboScale;

  @override
  void initState() {
    super.initState();
    _displayScore = ref.read(noirMindViewModelProvider).score;
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        setState(() {});
      });

    _comboController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _comboScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: 1.3),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1),
        weight: 4,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _comboController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _comboController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colorsFor(Theme.of(context).brightness);
    final highScore = ref.watch(
      noirMindViewModelProvider.select((s) => s.highScore),
    );
    final isQuestMode = ref.watch(
      noirMindViewModelProvider.select((s) => s.isQuestMode),
    );
    final targetScore = ref.watch(
      noirMindViewModelProvider.select((s) => s.targetScore),
    );
    final combo = ref.watch(
      noirMindViewModelProvider.select((s) => s.combo),
    );

    // スコアカウントアップ・コンボポップアニメーション
    ref
      ..listen(
        noirMindViewModelProvider.select((s) => s.score),
        (prev, next) {
          final from = prev ?? 0;
          _scoreController
            ..reset()
            ..addListener(() {
              final t = _scoreController.value;
              _displayScore =
                  (from + (next - from) * t).round();
            })
            ..forward();
        },
      )
      ..listen(
        noirMindViewModelProvider.select((s) => s.combo),
        (prev, next) {
          if (next > 0 && next != prev) {
            _comboController
              ..reset()
              ..forward();
          }
        },
      );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // スコア
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SCORE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '$_displayScore',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                  height: 1.1,
                ),
              ),
            ],
          ),
          // コンボバッジ
          if (combo > 1)
            AnimatedBuilder(
              animation: _comboScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _comboScale.value.clamp(0.0, 2.0),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'x$combo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
          // クエストモードはTARGET、クラシックモードはBEST
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isQuestMode ? 'TARGET' : 'BEST',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                isQuestMode ? '$targetScore' : '$highScore',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface.withValues(alpha: 0.5),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
