import 'dart:async';

import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository/firestore_learning_history_repository.dart';
import '../repository/learning_history_repository.dart';
import '../repository/local_learning_history_repository.dart';
import '../repository/synced_learning_history_repository.dart';
import 'data_sync_status_provider.dart';

const _lastSyncedUidKey = 'last_synced_uid';

final learningHistoryRepositoryProvider =
    Provider<LearningHistoryRepository>((ref) {
  final isPremium =
      ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false;
  final user = FirebaseAuth.instance.currentUser;
  final isLinked = user?.providerData.isNotEmpty ?? false;

  ref.listen<AsyncValue<PremiumState>>(premiumViewModelProvider,
      (prev, next) async {
    final wasPremium = prev?.asData?.value.isPremium ?? false;
    final nowPremium = next.asData?.value.isPremium ?? false;
    if (wasPremium && !nowPremium) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncedUidKey);
      ref.read(dataSyncStatusProvider.notifier).update(DataSyncStatus.idle);
    }
  });

  final local = LocalLearningHistoryRepository();

  if (!isPremium || !isLinked || user == null) return local;

  final remote = FirestoreLearningHistoryRepository(uid: user.uid);

  unawaited(
    _runSync(ref, local, remote, user.uid),
  );

  return SyncedLearningHistoryRepository(local: local, remote: remote);
});

Future<void> _runSync(
  Ref ref,
  LocalLearningHistoryRepository local,
  FirestoreLearningHistoryRepository remote,
  String uid,
) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(_lastSyncedUidKey) == uid) {
    ref.read(dataSyncStatusProvider.notifier).update(DataSyncStatus.synced);
    return;
  }
  try {
    ref.read(dataSyncStatusProvider.notifier).update(DataSyncStatus.syncing);
    await remote.runInitialSyncIfNeeded(local: local, uid: uid);
    ref.read(dataSyncStatusProvider.notifier).update(DataSyncStatus.synced);
  } catch (_) {
    ref.read(dataSyncStatusProvider.notifier).update(DataSyncStatus.failed);
  }
}
