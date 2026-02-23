import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'quest_progress_view_model.freezed.dart';
part 'quest_progress_view_model.g.dart';

const _questMaxLevelKey = 'noir_mind_quest_max_level';

/// クエストモードの進捗状態。
@freezed
abstract class QuestProgressState with _$QuestProgressState {
  /// クエスト進捗状態を作成する。
  const factory QuestProgressState({
    /// 解放済みの最大レベル（初期値 1）。
    @Default(1) int maxUnlockedLevel,
  }) = _QuestProgressState;
}

/// クエストモードのレベル進捗を管理するビューモデル。
/// 解放済み最大レベルを SharedPreferences に永続化する。
@riverpod
class QuestProgressViewModel extends _$QuestProgressViewModel {
  @override
  QuestProgressState build() {
    _loadProgress();
    return const QuestProgressState();
  }

  void _loadProgress() {
    SharedPreferences.getInstance().then((prefs) {
      final value = prefs.getInt(_questMaxLevelKey);
      if (value != null && value > state.maxUnlockedLevel) {
        state = state.copyWith(maxUnlockedLevel: value);
      }
    });
  }

  /// 指定レベルをクリアし、次のレベルを解放する。
  Future<void> completeLevel(int level) async {
    final next = level + 1;
    if (next > state.maxUnlockedLevel) {
      state = state.copyWith(maxUnlockedLevel: next);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_questMaxLevelKey, next);
    }
  }
}
