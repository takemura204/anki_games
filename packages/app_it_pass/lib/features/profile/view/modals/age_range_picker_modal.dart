import 'package:app_it_pass/components/app_bottom_sheet.dart';
import 'package:app_it_pass/components/glass_widget.dart';
import 'package:app_it_pass/components/modal_handle.dart';
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:app_it_pass/features/profile/model/user_profile.dart';
import 'package:app_it_pass/features/profile/view/widgets/picker_confirm_button.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

class AgeRangePickerModal extends HookWidget {
  const AgeRangePickerModal({super.key, required this.current});

  final AgeRange? current;

  @override
  Widget build(BuildContext context) {
    final selected = useState<AgeRange?>(current);
    final c = context.appColors;

    return AppBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const ModalHandle(), const Gap(AppSpacing.sm)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: GlassContainer(
              cardRadius: AppBorderRadius.md,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: RadioGroup<AgeRange>(
                groupValue: selected.value,
                onChanged: (a) => selected.value = a,
                child: Column(
                  children: [
                    for (int i = 0; i < AgeRange.values.length; i++) ...[
                      if (i != 0)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: c.border1,
                        ),
                      InkWell(
                        onTap: () => selected.value = AgeRange.values[i],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Radio<AgeRange>(
                                value: AgeRange.values[i],
                                activeColor: AppColors.itPassSeed,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              Text(
                                AgeRange.values[i].label,
                                style: AppTextStyle.bodyMedium.copyWith(
                                  color: AgeRange.values[i] == selected.value
                                      ? AppColors.itPassSeed
                                      : c.fg,
                                  fontWeight:
                                      AgeRange.values[i] == selected.value
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          PickerConfirmButton(
            enabled: selected.value != null,
            onTap: () => Navigator.of(context).pop(selected.value),
          ),
        ],
      ),
    );
  }
}
