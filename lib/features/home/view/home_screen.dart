import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view/block_puzzle_screen.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:mono_games/features/home/view/widgets/quiz_start_bottom_sheet.dart';
import 'package:mono_games/features/quiz/view_model/quiz_view_model.dart';
import 'package:mono_games/features/settings/view/settings_dialog.dart';
import 'package:mono_games/i18n/translations.g.dart';

part 'widgets/level_chips.dart';

/// The home screen of Block. — a vocabulary learning app.
class HomeScreen extends HookConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameTheme = ref.watch(themeViewModelProvider);
    final brightness = Theme.of(context).brightness;
    final colors = gameTheme.colorsFor(brightness);
    final masteryBreakdowns = ref.watch(
      quizViewModelProvider.select((s) => s.masteryBreakdowns),
    );

    useEffect(
      () {
        ref.read(quizViewModelProvider.notifier).loadMasteryStats();
        // プロバイダーを早期作成して _loadPersistedData を完了させる。
        // Start ボタンが押されるより前にセーブデータがキャッシュに載るようにする。
        ref.read(blockPuzzleViewModelProvider.notifier);
        return null;
      },
      [],
    );

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    t.blockPuzzle.title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: colors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: colors.onSurface.withValues(alpha: 0.55),
                    ),
                    onPressed: () => showHomeSettingsDialog(context),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                t.quiz.sectionLevel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Gap(8),
              _LevelCards(
                colors: colors,
                masteryBreakdowns: masteryBreakdowns,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
