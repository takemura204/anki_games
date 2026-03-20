import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/i18n/translations.g.dart';

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
  var _displayScore = 0;
  late final AnimationController _scoreController;
  late final AnimationController _comboController;
  late final Animation<double> _comboScale;

  @override
  void initState() {
    super.initState();
    _displayScore = ref.read(blockPuzzleViewModelProvider).score;
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

  static String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colorsFor(Theme.of(context).brightness);
    final highScore = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.highScore),
    );
    final isQuestMode = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.isQuestMode),
    );
    final isTimeAttackMode = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.isTimeAttackMode),
    );
    final timeAttackRemaining = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.timeAttackRemainingSeconds),
    );
    // クエストモード: 残りノイズブロック数を表示
    final noiseBoard = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.noiseBoard),
    );
    final noiseCount = noiseBoard.isEmpty
        ? 0
        : noiseBoard.fold<int>(
            0,
            (int sum, List<int> row) =>
                sum + row.where((int hp) => hp > 0).length,
          );
    final combo = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.combo),
    );
    final quizMultiplier = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.quizMultiplier),
    );

    // スコアカウントアップ・コンボポップアニメーション
    ref
      ..listen(
        blockPuzzleViewModelProvider.select((s) => s.score),
        (prev, next) {
          final from = prev ?? 0;
          _scoreController
            ..reset()
            ..addListener(() {
              final t = _scoreController.value;
              _displayScore = (from + (next - from) * t).round();
            })
            ..forward();
        },
      )
      ..listen(
        blockPuzzleViewModelProvider.select((s) => s.combo),
        (prev, next) {
          if (next > 0 && next != prev) {
            _comboController
              ..reset()
              ..forward();
          }
        },
      )
      ..listen(
        blockPuzzleViewModelProvider.select((s) => s.quizMultiplier),
        (prev, next) {
          if (next > (prev ?? 1)) {
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
          // コンボバッジ / ×2ボーナスバッジ
          if (quizMultiplier > 1 || combo > 1)
            AnimatedBuilder(
              animation: _comboScale,
              builder: (context, child) => Transform.scale(
                scale: _comboScale.value.clamp(0.0, 2.0),
                child: child,
              ),
              child: quizMultiplier > 1
                  ? Container(
                      key: ValueKey('x$quizMultiplier'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.shade400.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        '×$quizMultiplier',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade400,
                        ),
                      ),
                    )
                  : Container(
                      key: const ValueKey('combo'),
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
          // タイムアタック=TIME、クエスト=NOISE、クラシック=BEST
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTimeAttackMode
                    ? t.blockPuzzle.timeAttackLabel
                    : isQuestMode
                        ? 'NOISE'
                        : 'BEST',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                isTimeAttackMode
                    ? _formatTime(timeAttackRemaining)
                    : isQuestMode
                        ? '$noiseCount'
                        : '$highScore',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isTimeAttackMode && timeAttackRemaining <= 30
                      ? colors.accent
                      : colors.onSurface.withValues(alpha: 0.5),
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
