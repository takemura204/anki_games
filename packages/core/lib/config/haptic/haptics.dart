import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 振動の強さ。
enum HapticType {
  /// 軽いタップ感。通常のボタン・メニュー・アイコンに使用。
  light,

  /// 中程度の押し込み感。確定・送信・次へなど主要アクションに使用。
  medium,

  /// スナップ感。タブ・チップ・フィルター切替など選択状態変化に使用。
  selection,
}

// ignore: avoid_classes_with_only_static_members
/// 振動ユーティリティ。
abstract final class Haptics {
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> of(HapticType type) => switch (type) {
        HapticType.light => HapticFeedback.lightImpact(),
        HapticType.medium => HapticFeedback.mediumImpact(),
        HapticType.selection => HapticFeedback.selectionClick(),
      };
}

/// [VoidCallback] に振動を付与する extension。
///
/// ```dart
/// IconButton(onPressed: onTap.withHaptic())
/// InkWell(onTap: onSave.withHaptic(HapticType.medium))
/// ```
extension HapticCallback on VoidCallback? {
  VoidCallback? withHaptic([HapticType type = HapticType.light]) {
    final fn = this;
    if (fn == null) return null;
    return () {
      Haptics.of(type);
      fn();
    };
  }
}

/// [GestureDetector] の代替。[onTap] に自動で振動を付与する。
///
/// 今後 `GestureDetector(onTap: fn)` の代わりにこれを使うことで
/// 振動が自動で付く。
///
/// ```dart
/// HapticTap(onTap: () => ..., child: MyWidget())
/// HapticTap(onTap: fn, type: HapticType.selection, child: MyWidget())
/// ```
class HapticTap extends StatelessWidget {
  const HapticTap({
    required this.child,
    this.onTap,
    this.type = HapticType.light,
    this.behavior,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final HapticType type;
  final HitTestBehavior? behavior;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap.withHaptic(type),
      behavior: behavior,
      child: child,
    );
  }
}
