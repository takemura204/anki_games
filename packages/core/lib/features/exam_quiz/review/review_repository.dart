import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ReviewRepository {
  Future<DateTime?> getLastRequestDate();
  Future<void> saveLastRequestDate(DateTime date);
}

class LocalReviewRepository implements ReviewRepository {
  static const _key = 'review_last_request_date';

  @override
  Future<DateTime?> getLastRequestDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> saveLastRequestDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, date.toIso8601String());
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (_) => LocalReviewRepository(),
);
