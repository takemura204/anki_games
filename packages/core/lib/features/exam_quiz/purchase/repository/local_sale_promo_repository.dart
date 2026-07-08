import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 1日1回のセール表示状態を SharedPreferences で管理するリポジトリ。
///
/// 毎日1回、アプリ起動時に [checkAndMarkDailySale] を呼ぶことで
/// セール画面の表示有無を判定する。
class LocalSalePromoRepository {
  static const _keySaleShownDate = 'sale_shown_date';

  /// セールを本日表示すべきかを判定し、表示する場合は今日の日付を記録する。
  ///
  /// - 本日未表示 → `true` を返し、表示済みとしてマーク
  /// - 本日表示済み → `false` を返す
  Future<bool> checkAndMarkDailySale() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keySaleShownDate);
    if (lastDate == _todayString()) return false;
    await prefs.setString(_keySaleShownDate, _todayString());
    return true;
  }

  /// デバッグ用: 今日の表示記録を消去して次回起動時に再表示させる。
  Future<void> restart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySaleShownDate);
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }
}

final salePromoRepositoryProvider = Provider<LocalSalePromoRepository>(
  (_) => LocalSalePromoRepository(),
);
