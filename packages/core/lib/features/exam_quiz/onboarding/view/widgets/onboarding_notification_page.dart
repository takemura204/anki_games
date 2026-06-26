import 'dart:ui';

import 'package:core/components/adaptive_body.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/config/brand/it_pass_color_scheme.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/notification/model/notification_time_slot.dart';
import 'package:core/features/exam_quiz/onboarding/view/widgets/onboarding_page_anim.dart';
import 'package:core/features/exam_quiz/onboarding/view_model/onboarding_ui_notifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingNotificationPage extends ConsumerStatefulWidget {
  const OnboardingNotificationPage({super.key, required this.isLoading});

  final bool isLoading;

  @override
  ConsumerState<OnboardingNotificationPage> createState() =>
      _OnboardingNotificationPageState();
}

class _OnboardingNotificationPageState
    extends ConsumerState<OnboardingNotificationPage>
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
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xxxl,
          AppSpacing.md,
          bottom + AppSpacing.onboardingFooterClearance + AppSpacing.sm,
        ),
        child: Column(
          children: [
            // Group 1: ヘッダー
            OnboardingFadeSlide(
              fade: _anim.topFade,
              slide: _anim.topSlide,
              child: Column(
                children: [
                  Icon(Icons.notifications_rounded, size: 40, color: c.fg),
                  const Gap(AppSpacing.md),
                  Text(
                    'リマインダーで\n継続をサポート',
                    style: AppTextStyle.titleLarge.copyWith(
                      color: c.fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(AppSpacing.md),
                  Text(
                    '学習したい時間を教えてください。\nあなたの続けやすい時間にリマインドします。',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: c.fgShade400,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.xl),
            // Group 2: 時間帯選択リスト
            OnboardingFadeSlide(
              fade: _anim.bottomFade,
              slide: _anim.bottomSlide,
              child: Column(
                children: NotificationTimeSlot.values
                    .map(
                      (slot) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _NotificationSlotRadioCard(
                          slot: slot,
                          isSelected: ob.selectedNotificationSlot == slot,
                          customHour: ob.selectedNotificationSlot == slot
                              ? ob.customNotificationHour
                              : null,
                          customMinute: ob.selectedNotificationSlot == slot
                              ? ob.customNotificationMinute
                              : null,
                          onTap: () => notifier.selectNotificationSlot(slot),
                          onCustomTimeChanged: notifier.setCustomNotificationTime,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _NotificationSlotRadioCard extends StatelessWidget {
  const _NotificationSlotRadioCard({
    required this.slot,
    required this.isSelected,
    required this.onTap,
    required this.onCustomTimeChanged,
    this.customHour,
    this.customMinute,
  });

  final NotificationTimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(int hour, int minute) onCustomTimeChanged;
  final int? customHour;
  final int? customMinute;

  int get _displayHour => customHour ?? slot.hour;
  int get _displayMinute => customMinute ?? slot.minute;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassContainer(
      cardRadius: AppBorderRadius.md,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorderRadius.md,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          decoration: BoxDecoration(
            borderRadius: AppBorderRadius.md,
            border: Border.all(
              color: isSelected ? ItPassColors.seed : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onTap.withHaptic(HapticType.selection),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: AnimatedSwitcher(
                    duration: AppAnimation.fast,
                    child: isSelected
                        ? const Icon(
                            Icons.radio_button_checked_rounded,
                            key: ValueKey('checked'),
                            color: ItPassColors.seed,
                            size: 22,
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            key: const ValueKey('unchecked'),
                            color: c.fgShade200,
                            size: 22,
                          ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: AppBorderRadius.md,
                  onTap: onTap.withHaptic(HapticType.selection),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          slot.notificationIcon,
                          size: 20,
                          color: isSelected ? c.fg : c.fgShade300,
                        ),
                        const Gap(AppSpacing.sm),
                        Text(
                          slot.displayLabel,
                          style: AppTextStyle.bodySmall.copyWith(
                            color: isSelected ? c.fg : c.fgShade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GlassButton(
                  cardRadius: AppBorderRadius.sm,
                  child: TextButton(
                    onPressed: isSelected
                        ? () => _showTimePicker(context)
                        : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '${_twoDigit(_displayHour)}:${_twoDigit(_displayMinute)}',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: isSelected ? c.fg : c.fgShade300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');

  void _showTimePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: const BoxConstraints(),
      builder: (_) => _TimePickerSheet(
        initialHour: _displayHour,
        initialMinute: _displayMinute,
        onConfirm: onCustomTimeChanged,
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({
    required this.initialHour,
    required this.initialMinute,
    required this.onConfirm,
  });

  final int initialHour;
  final int initialMinute;
  final void Function(int hour, int minute) onConfirm;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceSheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: c.border1)),
          ),
          padding: EdgeInsets.only(bottom: bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'キャンセル',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: c.fgShade400,
                        ),
                      ),
                    ),
                    Text(
                      '通知時間',
                      style: AppTextStyle.titleSmall.copyWith(
                        color: c.fg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onConfirm(_hour, _minute);
                        Navigator.pop(context);
                      },
                      child: Text(
                        '完了',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: ItPassColors.seed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _hour,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => setState(() => _hour = i),
                        children: List.generate(
                          24,
                          (i) => Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: AppTextStyle.titleMedium.copyWith(
                                color: c.fg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      ':',
                      style: AppTextStyle.titleLarge.copyWith(color: c.fg),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _minute ~/ 5,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) =>
                            setState(() => _minute = i * 5),
                        children: List.generate(
                          12,
                          (i) => Center(
                            child: Text(
                              (i * 5).toString().padLeft(2, '0'),
                              style: AppTextStyle.titleMedium.copyWith(
                                color: c.fg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
