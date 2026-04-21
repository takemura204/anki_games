import 'package:core/config/constants/core_package_asset.dart';
import 'package:core/config/extensions/context_extension.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/quiz/view_model/quiz_view_model.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../block_puzzle/view_model/block_puzzle_view_model.dart';
import '../view_model/home_view_model.dart';

part 'widgets/level_chips.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);

    if (homeState.isLoading) {
      return Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: context.colorScheme.primary,
          ),
        ),
      );
    }

    final colorScheme = context.colorScheme;
    final brightness = Theme.of(context).brightness;
    final masteryBreakdowns = ref.watch(
      quizViewModelProvider.select((s) => s.masteryBreakdowns),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  onPressed: () =>
                      ref.read(homeViewModelProvider.notifier).onSettingsTap(),
                ),
              ),
              const Spacer(),
              _ModeHeroPage(
                brightness: brightness,
                modeLabel: t.blockPuzzle.title,
              ),
              const SizedBox(height: 12),
              Text(
                t.blockPuzzle.title,
                style: AppTextStyle.headlineLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                t.blockPuzzle.subtitle,
                style: AppTextStyle.labelMedium.copyWith(
                  letterSpacing: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _LevelCards(masteryBreakdowns: masteryBreakdowns),
              Gap(context.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeHeroPage extends StatelessWidget {
  const _ModeHeroPage({
    required this.brightness,
    required this.modeLabel,
  });

  final Brightness brightness;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          brightness == Brightness.dark
              ? corePackageAssetKey('assets/logo/logo_dark.png')
              : corePackageAssetKey('assets/logo/logo_light.png'),
          height: 140,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            modeLabel.toUpperCase(),
            style: AppTextStyle.labelSmall.copyWith(
              letterSpacing: 1.2,
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
