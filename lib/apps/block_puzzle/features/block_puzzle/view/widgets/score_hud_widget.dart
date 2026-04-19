import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/game_theme.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:anki_games/common/config/styles/app_text_style.dart';
import 'package:anki_games/common/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// スコアを中央に大きく表示するHUD。
class ScoreHudWidget extends ConsumerStatefulWidget {
  /// スコアHUDウィジェットを作成する。
  const ScoreHudWidget({required this.theme, super.key});

  /// 現在のゲームテーマ。
  final GameTheme theme;

  @override
  ConsumerState<ScoreHudWidget> createState() => _ScoreHudWidgetState();
}

class _ScoreHudWidgetState extends ConsumerState<ScoreHudWidget>
    with SingleTickerProviderStateMixin {
  var _displayScore = 0;
  late final AnimationController _scoreController;

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
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colorsFor(Theme.of(context).brightness);
    ref.listen(
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
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.blockPuzzle.scoreLabel,
          style: AppTextStyle.labelMedium.copyWith(
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          '$_displayScore',
          style: AppTextStyle.displaySmall.copyWith(
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}
