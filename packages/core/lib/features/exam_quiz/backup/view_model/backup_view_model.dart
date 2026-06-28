import 'package:core/config/brand/brand_config.dart';
import 'package:core/features/exam_quiz/auth/auth_user_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../learning/providers/learning_history_provider.dart';
import '../../note/providers/bookmark_provider.dart';
import '../../streak/view_model/streak_view_model.dart';
import '../service/backup_service.dart';

class BackupViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> upload() async {
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    final prefix = ref.read(brandConfigProvider).analyticsBrandKey;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => BackupService(uid: uid, prefsPrefix: prefix).upload(),
    );
    if (!state.hasError) {
      ref
        ..invalidate(bookmarkProvider)
        ..invalidate(streakViewModelProvider)
        ..invalidate(learningHistoryRepositoryProvider);
    }
  }

  Future<DateTime?> lastBackupAt() async {
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return null;
    final prefix = ref.read(brandConfigProvider).analyticsBrandKey;
    return BackupService(uid: uid, prefsPrefix: prefix).localBackupAt();
  }
}

final backupViewModelProvider =
    AsyncNotifierProvider<BackupViewModel, void>(
  BackupViewModel.new,
);
