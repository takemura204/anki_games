/// 4pt グリッドベースのスペーシング定数。
///
/// Widget のパディング・マージン・Gap に使う。
/// `Gap(AppSpacing.md)` のように gap パッケージと組み合わせる。
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// オンボーディング下部フッターオーバーレイのクリアランス。
  static const double onboardingFooterClearance = 80;
}

/// 画面幅ブレークポイント定数。
///
/// `AdaptiveBody` や `LayoutBuilder` の判断基準として使う。
/// デバイス種別ではなく利用可能幅で判断する。
abstract final class AppBreakpoints {
  /// コンパクト幅の上限。これを超えるとタブレット扱い。
  static const double compact = 600;
}
