import 'package:core/config/brand/brand_config.dart';
import 'package:core/features/exam_quiz/auth/auth_user_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../backup/providers/auto_restore_message_provider.dart';
import '../../backup/service/backup_service.dart';
import '../repository/learning_history_repository.dart';
import '../repository/local_learning_history_repository.dart';

class LearningHistoryNotifier
    extends AsyncNotifier<LearningHistoryRepository> {
  @override
  Future<LearningHistoryRepository> build() async {
    final isSync = ref.watch(isSyncEnabledProvider);
    final prefix = ref.watch(brandConfigProvider).analyticsBrandKey;
    final local = LocalLearningHistoryRepository(prefsPrefix: prefix);

    if (!isSync) return local;

    final user = ref.watch(authUserProvider).asData?.value;
    if (user == null) return local;

    final didRestore =
        await BackupService(uid: user.uid, prefsPrefix: prefix).downloadIfNewer();

    if (didRestore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(autoRestoreMessageProvider.notifier)
            .update('クラウドから復元しました');
      });
    }

    return local;
  }
}

final learningHistoryRepositoryProvider =
    AsyncNotifierProvider<LearningHistoryNotifier, LearningHistoryRepository>(
  LearningHistoryNotifier.new,
);
