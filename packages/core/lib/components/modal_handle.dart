import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:flutter/material.dart';

class ModalHandle extends StatelessWidget {
  const ModalHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.appColors.fgShade100,
            borderRadius:
                AppBorderRadius.sm - const BorderRadius.all(Radius.circular(6)),
          ),
        ),
      ),
    );
  }
}
