part of '../block_puzzle_screen.dart';

/// ゲーム画面上部ヘッダー。
///
/// 左: ハイスコア、中央: 現在スコア、右: 設定ボタンを横並びで配置する。
class GameHeaderWidget extends ConsumerStatefulWidget {
  const GameHeaderWidget({super.key});

  @override
  ConsumerState<GameHeaderWidget> createState() => _GameHeaderWidgetState();
}

class _GameHeaderWidgetState extends ConsumerState<GameHeaderWidget>
    with SingleTickerProviderStateMixin {
  var _displayScore = 0;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _displayScore = ref.read(blockPuzzleViewModelProvider).score;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeViewModelProvider);
    final colors = theme.colorsFor(Theme.of(context).brightness);
    final highScore = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.highScore),
    );

    ref.listen(
      blockPuzzleViewModelProvider.select((s) => s.score),
      (prev, next) {
        final from = prev ?? 0;
        _controller
          ..reset()
          ..addListener(() {
            _displayScore = (from + (next - from) * _controller.value).round();
          })
          ..forward();
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HighScoreLabel(
                highScore: highScore,
                color: colors.onSurface.withValues(alpha: 0.45),
              ),
              _SettingsButton(color: colors.onSurface.withValues(alpha: 0.55)),
            ],
          ),
          _CurrentScoreLabel(
            score: _displayScore,
            gameTheme: theme,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _HighScoreLabel extends StatelessWidget {
  const _HighScoreLabel({required this.highScore, required this.color});

  final int highScore;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.emoji_events_rounded, size: 20, color: color),
        Text(
          '$highScore',
          style: AppTextStyle.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _CurrentScoreLabel extends StatelessWidget {
  const _CurrentScoreLabel({
    required this.score,
    required this.gameTheme,
    required this.colors,
  });

  final int score;
  final GameTheme gameTheme;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Score',
          style: AppTextStyle.labelMedium
              .copyWith(color: colors.onSurface.withValues(alpha: 0.5)),
        ),
        Text(
          '$score',
          textAlign: TextAlign.center,
          style: AppTextStyle.headlineLarge.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }
}

class _SettingsButton extends ConsumerWidget {
  const _SettingsButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.settings_outlined, color: color, size: 22),
      onPressed: () => ref.read(modalSheetRouterProvider).showGameSettings(),
    );
  }
}
