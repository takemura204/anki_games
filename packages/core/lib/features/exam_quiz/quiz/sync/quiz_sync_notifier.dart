import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../config/exam_config.dart';
import '../datasource/quiz_local_datasource.dart';
import '../datasource/quiz_remote_datasource.dart';
import '../model/quiz_manifest.dart';

part 'quiz_sync_notifier.g.dart';

/// クイズデータの同期状態。
sealed class QuizSyncState {
  const QuizSyncState();
}

/// キャッシュあり、即利用可（バックグラウンド更新中の場合もある）。
class QuizSyncReady extends QuizSyncState {
  const QuizSyncReady({this.isUpdating = false});
  final bool isUpdating;
}

/// ネットワークエラー（キャッシュなし）。
class QuizSyncError extends QuizSyncState {
  const QuizSyncError(this.message);
  final String message;
}

/// 初回ダウンロードの進捗（null = ダウンロード中でない, 0.0〜1.0 = 進捗）。
///
/// [quizSyncProvider] の build() が完了するまでの間だけ非 null になる。
/// QuizSyncNotifier の state に中間状態を混ぜないことで
/// [AsyncNotifierProvider.future] の early resolve を防ぐ。
final quizDownloadProgressProvider =
    NotifierProvider<_DownloadProgressNotifier, double?>(
  _DownloadProgressNotifier.new,
);

class _DownloadProgressNotifier extends Notifier<double?> {
  @override
  double? build() => null;

  // ignore: use_setters_to_change_properties
  void update(double? value) => state = value;
}

/// バックグラウンドでクイズデータを同期する Notifier。
///
/// - キャッシュあり: `QuizSyncReady` を即返却 → バックグラウンドで差分更新
/// - キャッシュなし: build() 完了まで AsyncLoading → 完了後 `QuizSyncReady`
/// - ネットワークエラー（キャッシュなし）: `QuizSyncError`
@Riverpod(keepAlive: true)
class QuizSyncNotifier extends _$QuizSyncNotifier {
  @override
  Future<QuizSyncState> build() async {
    final examConfig = ref.read(examConfigProvider);
    final examTypeKey = examConfig.examTypeKey;
    final local = QuizLocalDatasource.instance;
    final remote = ref.read(_quizRemoteDatasourceProvider);

    final cachedVersion = await local.readCachedVersion(examTypeKey);
    final hasSomeCache = cachedVersion != null;

    if (hasSomeCache) {
      // キャッシュあり → 即利用可能にして、バックグラウンドで差分更新
      unawaited(_syncInBackground(examTypeKey, remote, local));
      return const QuizSyncReady();
    }

    // 初回: manifest を取得してダウンロード
    try {
      final manifest = await remote.fetchManifest();
      final examManifest = manifest.exams[examTypeKey];
      if (examManifest == null) {
        return QuizSyncError('$examTypeKey のデータが見つかりません');
      }
      await _downloadAll(examTypeKey, examManifest, remote, local);
      return const QuizSyncReady();
    } on QuizRemoteException catch (e) {
      return QuizSyncError(e.message);
    } on Exception catch (e) {
      return QuizSyncError('データの取得に失敗しました: $e');
    }
  }

  /// バックグラウンドで差分更新（エラーは無視して次回に持ち越す）。
  Future<void> _syncInBackground(
    String examTypeKey,
    QuizRemoteDatasource remote,
    QuizLocalDatasource local,
  ) async {
    try {
      final manifest = await remote.fetchManifest();
      final examManifest = manifest.exams[examTypeKey];
      if (examManifest == null) return;

      final cachedVersion = await local.readCachedVersion(examTypeKey);
      if (cachedVersion == examManifest.version) return;

      // バージョンが変わったファイルのみ更新
      await _downloadDiff(examTypeKey, examManifest, remote, local);

      // キャッシュのリセットを通知
      ref.invalidateSelf();
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[QuizSync] バックグラウンド更新エラー: $e');
    }
  }

  /// manifest 内の全ファイルをダウンロードし進捗を別 provider で通知する。
  Future<void> _downloadAll(
    String examTypeKey,
    ExamManifest examManifest,
    QuizRemoteDatasource remote,
    QuizLocalDatasource local,
  ) async {
    final files = examManifest.files;
    for (var i = 0; i < files.length; i++) {
      final entry = files[i];
      final bytes = await remote.downloadFile(entry);
      await local.writeFile(examTypeKey, entry.name, bytes);
      ref.read(quizDownloadProgressProvider.notifier).update(
            (i + 1) / files.length,
          );
    }
    await local.writeCachedVersion(examTypeKey, examManifest.version);
    ref.read(quizDownloadProgressProvider.notifier).update(null);
  }

  /// SHA256 が異なるファイルのみダウンロードする。
  Future<void> _downloadDiff(
    String examTypeKey,
    ExamManifest examManifest,
    QuizRemoteDatasource remote,
    QuizLocalDatasource local,
  ) async {
    for (final entry in examManifest.files) {
      final isValid =
          await local.isFileValid(examTypeKey, entry.name, entry.sha256);
      if (isValid) continue;
      final bytes = await remote.downloadFile(entry);
      await local.writeFile(examTypeKey, entry.name, bytes);
    }
    await local.writeCachedVersion(examTypeKey, examManifest.version);
  }
}

/// Firebase Hosting の base URL。本番 URL をここで一元管理する。
const _quizDataBaseUrl = 'https://quiz-data-anki-quiz-dev.web.app';

final Provider<QuizRemoteDatasource> _quizRemoteDatasourceProvider = Provider(
  (_) => QuizRemoteDatasource(baseUrl: _quizDataBaseUrl),
);
