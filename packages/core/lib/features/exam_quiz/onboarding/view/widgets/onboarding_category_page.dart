import 'package:core/components/adaptive_body.dart';
import 'package:core/components/category_filter_section.dart';
import 'package:core/config/brand/it_pass_color_scheme.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/onboarding/view/widgets/onboarding_page_anim.dart';
import 'package:core/features/exam_quiz/onboarding/view_model/onboarding_ui_notifier.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingCategoryPage extends ConsumerStatefulWidget {
  const OnboardingCategoryPage({super.key});

  @override
  ConsumerState<OnboardingCategoryPage> createState() =>
      _OnboardingCategoryPageState();
}

class _OnboardingCategoryPageState extends ConsumerState<OnboardingCategoryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final OnboardingPageAnim _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _anim = OnboardingPageAnim.from(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ob = ref.watch(onboardingUiProvider);
    final notifier = ref.read(onboardingUiProvider.notifier);
    final bottom = MediaQuery.of(context).padding.bottom;
    final c = context.appColors;

    return AdaptiveBody(
      child: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xxxl,
              AppSpacing.md,
              bottom + AppSpacing.onboardingFooterClearance + AppSpacing.sm,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                OnboardingFadeSlide(
                  fade: _anim.topFade,
                  slide: _anim.topSlide,
                  child: Center(
                    child: Column(
                      children: [
                        Icon(AppIcons.filter, color: c.fg, size: 40),
                        const Gap(AppSpacing.md),
                        Text(
                          '学習範囲を絞り込み',
                          style: AppTextStyle.titleLarge.copyWith(
                            color: c.fg,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(AppSpacing.md),
                        Text(
                          '分野を指定して出題範囲を絞り込みましょう。\n※後から変更可能です。',
                          style: AppTextStyle.bodyMedium.copyWith(
                            color: c.fg,
                            height: 1.7,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(AppSpacing.xl),
                OnboardingFadeSlide(
                  fade: _anim.bottomFade,
                  slide: _anim.bottomSlide,
                  child: Column(
                    children: ref
                        .watch(examConfigProvider)
                        .categoryTree
                        .entries
                        .map(
                          (entry) => CategoryExpansionTile(
                            title: entry.key,
                            isSelected: ob.selectedSystems.contains(entry.key),
                            isExpanded: ob.expandedSystems.contains(entry.key),
                            onSelectToggle: () {
                              if (ob.selectedSystems.contains(entry.key)) {
                                notifier.deselectSystem(entry.key);
                              } else {
                                notifier.selectSystem(entry.key);
                              }
                            },
                            onExpansionToggle: () =>
                                notifier.toggleExpansion(entry.key),
                            child: Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: entry.value
                                  .map(
                                    (major) => CategoryMajorChip(
                                      label: major,
                                      isSelected: ob.selectedMajors.contains(
                                        major,
                                      ),
                                      onTap: () => notifier.toggleMajor(major),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
