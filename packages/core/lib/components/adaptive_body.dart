import 'package:core/config/styles/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// 親の割当幅が [maxWidth] を超えた場合にのみ、コンテンツを中央揃え・幅制限する。
///
/// `MediaQuery` ではなく `LayoutBuilder`（親の実割当幅）で判断するため、
/// iPad Split View / Slide Over でも正しく動作する。
///
/// - phone（≤ maxWidth）: child をそのまま返す（レイアウト変化なし）
/// - tablet（> maxWidth）: `Center` + `ConstrainedBox(maxWidth)` で囲む
class AdaptiveBody extends StatelessWidget {
  const AdaptiveBody({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.compact,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
