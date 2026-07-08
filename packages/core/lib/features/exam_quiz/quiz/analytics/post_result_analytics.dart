import 'package:firebase_analytics/firebase_analytics.dart';

/// クイズ結果ページ後のアクション計測イベントを管理するサービス。
///
/// 広告・レビュー・セールそれぞれの impression/dismiss/purchase を
/// Firebase Analytics に送信し、調整役の効果をファネルで追跡する。
class PostResultAnalytics {
  const PostResultAnalytics._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static const _eventResultAction = 'quiz_result_post_action';
  static const _paramActionType = 'action_type';
  static const _paramIsPremium = 'is_premium';

  static const _actionAd = 'ad';
  static const _actionReview = 'review';
  static const _actionSale = 'sale';
  static const _actionNone = 'none';

  static const _eventAdImpression = 'result_ad_impression';
  static const _eventAdDismiss = 'result_ad_dismiss';
  static const _eventReviewRequest = 'result_review_request';
  static const _eventSaleImpression = 'result_sale_impression';
  static const _eventSaleDismiss = 'result_sale_dismiss';
  static const _eventSaleCtaTap = 'result_sale_cta_tap';

  /// 結果ページ後アクションが決定したときに呼ぶ。
  static Future<void> logResultAction({
    required String actionType,
    required bool isPremium,
  }) =>
      _analytics.logEvent(
        name: _eventResultAction,
        parameters: {
          _paramActionType: actionType,
          _paramIsPremium: isPremium ? 1 : 0,
        },
      );

  /// 広告が表示されたとき（showIfReady が true を返したとき）に呼ぶ。
  static Future<void> logAdImpression() =>
      _analytics.logEvent(name: _eventAdImpression);

  /// 広告を閉じたときに呼ぶ（onDismissed コールバックで）。
  static Future<void> logAdDismiss() =>
      _analytics.logEvent(name: _eventAdDismiss);

  /// in_app_review の requestReview() を呼び出したときに呼ぶ。
  ///
  /// OS のスロットルで実際にダイアログが出るかは不明だが、
  /// 訴求を試みた回数としてカウントできる。
  static Future<void> logReviewRequest() =>
      _analytics.logEvent(name: _eventReviewRequest);

  /// SaleSheet が表示されたときに呼ぶ。
  static Future<void> logSaleImpression() =>
      _analytics.logEvent(name: _eventSaleImpression);

  /// SaleSheet が閉じられたときに呼ぶ（購入・キャンセル問わず）。
  static Future<void> logSaleDismiss() =>
      _analytics.logEvent(name: _eventSaleDismiss);

  /// SaleSheet の購入ボタンがタップされたときに呼ぶ。
  static Future<void> logSaleCtaTap() =>
      _analytics.logEvent(name: _eventSaleCtaTap);

  static String get actionAd => _actionAd;
  static String get actionReview => _actionReview;
  static String get actionSale => _actionSale;
  static String get actionNone => _actionNone;
}
