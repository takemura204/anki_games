import '../model/streak_data.dart';

abstract interface class StreakRepository {
  Future<StreakData> load();
  Future<StreakData> recordStudy(DateTime today);
}
