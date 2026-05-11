import 'package:hooks_riverpod/hooks_riverpod.dart';

enum DataSyncStatus { idle, syncing, synced, failed }

class DataSyncStatusNotifier extends Notifier<DataSyncStatus> {
  @override
  DataSyncStatus build() => DataSyncStatus.idle;

  void update(DataSyncStatus status) => state = status;
}

final dataSyncStatusProvider =
    NotifierProvider<DataSyncStatusNotifier, DataSyncStatus>(
  DataSyncStatusNotifier.new,
);
