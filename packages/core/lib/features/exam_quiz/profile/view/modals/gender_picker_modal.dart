import 'package:core/components/app_bottom_sheet.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/components/modal_handle.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/extensions/context_extension.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/profile/model/user_profile.dart';
import 'package:core/features/exam_quiz/profile/view/widgets/picker_confirm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

class GenderPickerModal extends HookWidget {
  const GenderPickerModal({super.key, required this.current});

  final Gender? current;

  @override
  Widget build(BuildContext context) {
    final selected = useState<Gender?>(current);
    final c = context.appColors;

    return AppBottomSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: context.height * 0.65),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [ModalHandle(), Gap(AppSpacing.sm)],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: GlassContainer(
                  cardRadius: AppBorderRadius.md,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: RadioGroup<Gender>(
                    groupValue: selected.value,
                    onChanged: (g) => selected.value = g,
                    child: Column(
                      children: [
                        for (int i = 0; i < Gender.values.length; i++) ...[
                          if (i != 0)
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: c.border1,
                            ),
                          InkWell(
                            onTap: () => selected.value = Gender.values[i],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  Radio<Gender>(
                                    value: Gender.values[i],
                                    activeColor: AppPalette.seed,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  Text(
                                    Gender.values[i].label,
                                    style: AppTextStyle.bodyMedium.copyWith(
                                      color:
                                          Gender.values[i] == selected.value
                                          ? AppPalette.seed
                                          : c.fg,
                                      fontWeight:
                                          Gender.values[i] == selected.value
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
            ),
            const Gap(AppSpacing.md),
            PickerConfirmButton(
              enabled: selected.value != null,
              onTap: () => Navigator.of(context).pop(selected.value),
            ),
          ],
        ),
      ),
    );
  }
}
