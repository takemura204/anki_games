import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/streak_data.dart';
import '../repository/local_streak_repository.dart';
import '../repository/streak_repository.dart';

part 'streak_view_model.g.dart';

@Riverpod(keepAlive: true)
class StreakViewModel extends _$StreakViewModel {
  final StreakRepository _repo = LocalStreakRepository();

  @override
  StreakData build() {
    _load();
    return const StreakData();
  }

  void _load() {
    _repo.load().then((data) {
      state = data;
    });
  }

  Future<void> recordStudy() async {
    final updated = await _repo.recordStudy(DateTime.now());
    state = updated;
  }

  void clearBanner() {
    state = state.copyWith(showBanner: false);
  }

  Future<void> showBannerForDebug() async {
    state = state.copyWith(showBanner: false);
    await Future<void>.delayed(Duration.zero);
    state = state.copyWith(showBanner: true);
  }

  void recordPreviewStudy() {
    state = state.copyWith(
      currentStreak: 3,
      showBanner: true,
    );
  }
}
