import 'dart:math' show max;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../daily_study_log/model/daily_study_log.dart';
import '../../daily_study_log/repository/local_daily_study_log_repository.dart';
import '../../learning/model/question_learning_stats.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../../note/repository/local_bookmark_repository.dart';
import '../../streak/model/streak_data.dart';
import '../../streak/repository/local_streak_repository.dart';

const _lastBackupAtKeyPrefix = 'last_backup_at_';

class BackupService {
  BackupService({required this.uid, required this.prefsPrefix});

  final String uid;
  final String prefsPrefix;

  String get _lastBackupAtKey => '$_lastBackupAtKeyPrefix$uid';

  DocumentReference<Map<String, dynamic>> get _backupDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('backups')
          .doc('latest');

  Future<void> upload() async {
    final localData = await _readLocal();

    var merged = <String, dynamic>{};
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(_backupDoc);
      final remoteData =
          snap.exists ? snap.data()! : <String, dynamic>{};
      merged = _mergeData(localData, remoteData);
      tx.set(_backupDoc, {...merged, 'backedUpAt': FieldValue.serverTimestamp()});
    });

    await _saveToLocal(merged);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupAtKey, DateTime.now().toIso8601String());
  }

  /// Firestore が新しければマージ復元し true を返す。変化なしなら false。
  Future<bool> downloadIfNewer() async {
    final snap = await _backupDoc.get();
    if (!snap.exists) return false;
    final data = snap.data()!;

    final remoteTs = (data['backedUpAt'] as Timestamp?)?.toDate();
    if (remoteTs == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final localTsStr = prefs.getString(_lastBackupAtKey);
    final localTs = localTsStr != null ? DateTime.tryParse(localTsStr) : null;

    if (localTs != null && !remoteTs.isAfter(localTs)) return false;

    final localData = await _readLocal();
    final merged = _mergeData(localData, data);
    await _saveToLocal(merged);

    return true;
  }

  Future<DateTime?> localBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastBackupAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ---- private helpers ----

  Future<Map<String, dynamic>> _readLocal() async {
    final localHistory = LocalLearningHistoryRepository(prefsPrefix: prefsPrefix);
    final history = await localHistory.loadAll();
    final logs = await LocalDailyStudyLogRepository().loadAll();
    final streak = await LocalStreakRepository().load();
    final bookmarks = await LocalBookmarkRepository(prefsPrefix: prefsPrefix).loadAll();
    return {
      'learningHistory': history.map((k, v) => MapEntry(k, v.toJson())),
      'dailyStudyLogs': logs.map((l) => l.toJson()).toList(),
      'streak': streak.toJson(),
      'bookmarks': bookmarks.toList(),
    };
  }

  Future<void> _saveToLocal(Map<String, dynamic> data) async {
    final localHistory = LocalLearningHistoryRepository(prefsPrefix: prefsPrefix);
    final localDailyLog = LocalDailyStudyLogRepository();
    final localStreak = LocalStreakRepository();
    final localBookmark = LocalBookmarkRepository(prefsPrefix: prefsPrefix);

    final historyRaw = data['learningHistory'] as Map<String, dynamic>? ?? {};
    await localHistory.saveAll(
      historyRaw.map(
        (k, v) => MapEntry(
          k,
          QuestionLearningStats.fromJson(v as Map<String, dynamic>),
        ),
      ),
    );

    final logsRaw = data['dailyStudyLogs'] as List<dynamic>? ?? [];
    await localDailyLog.saveAll(
      logsRaw
          .cast<Map<String, dynamic>>()
          .map(DailyStudyLog.fromJson)
          .toList(),
    );

    final streakRaw = data['streak'] as Map<String, dynamic>?;
    if (streakRaw != null) {
      await localStreak.saveForSync(StreakData.fromJson(streakRaw));
    }

    final bookmarksRaw = data['bookmarks'] as List<dynamic>? ?? [];
    await localBookmark.saveAll(bookmarksRaw.cast<String>().toSet());
  }

  Map<String, dynamic> _mergeData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // learningHistory: per-key max counts, newer lastAnsweredAt
    final localHistory =
        (local['learningHistory'] as Map<String, dynamic>?) ?? {};
    final remoteHistory =
        (remote['learningHistory'] as Map<String, dynamic>?) ?? {};
    final mergedHistory = <String, dynamic>{};
    for (final key in {...localHistory.keys, ...remoteHistory.keys}) {
      final l = localHistory[key] as Map<String, dynamic>?;
      final r = remoteHistory[key] as Map<String, dynamic>?;
      if (l == null) {
        mergedHistory[key] = r;
      } else if (r == null) {
        mergedHistory[key] = l;
      } else {
        final ls = QuestionLearningStats.fromJson(l);
        final rs = QuestionLearningStats.fromJson(r);
        final lAt = ls.lastAnsweredAt;
        final rAt = rs.lastAnsweredAt;
        final localNewer =
            lAt != null && (rAt == null || lAt.isAfter(rAt));
        mergedHistory[key] = QuestionLearningStats(
          correctCount: max(ls.correctCount, rs.correctCount),
          wrongCount: max(ls.wrongCount, rs.wrongCount),
          lastAnsweredAt: localNewer ? lAt : rAt,
          lastWasCorrect:
              localNewer ? ls.lastWasCorrect : rs.lastWasCorrect,
          lastSelectedLabel:
              localNewer ? ls.lastSelectedLabel : rs.lastSelectedLabel,
        ).toJson();
      }
    }

    // dailyStudyLogs: per-date max values
    final localLogs =
        (local['dailyStudyLogs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
    final remoteLogs =
        (remote['dailyStudyLogs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
    final logsByDate = <String, Map<String, dynamic>>{};
    for (final log in [...localLogs, ...remoteLogs]) {
      final date = log['date'] as String;
      final existing = logsByDate[date];
      if (existing == null) {
        logsByDate[date] = Map<String, dynamic>.from(log);
      } else {
        logsByDate[date] = {
          'date': date,
          'studySeconds': max(
            log['studySeconds'] as int? ?? 0,
            existing['studySeconds'] as int? ?? 0,
          ),
          'newReviewCount': max(
            log['newReviewCount'] as int? ?? 0,
            existing['newReviewCount'] as int? ?? 0,
          ),
          'answeredCount': max(
            log['answeredCount'] as int? ?? 0,
            existing['answeredCount'] as int? ?? 0,
          ),
          'correctCount': max(
            log['correctCount'] as int? ?? 0,
            existing['correctCount'] as int? ?? 0,
          ),
        };
      }
    }

    // streak: union dates, max currentStreak/freezeCount, newer lastStudiedDate
    final ls = (local['streak'] as Map<String, dynamic>?) ?? {};
    final rs = (remote['streak'] as Map<String, dynamic>?) ?? {};
    final localStudied =
        (ls['studiedDates'] as List<dynamic>?)?.cast<String>().toSet() ?? {};
    final remoteStudied =
        (rs['studiedDates'] as List<dynamic>?)?.cast<String>().toSet() ?? {};
    final localFrozen =
        (ls['frozenDates'] as List<dynamic>?)?.cast<String>().toSet() ?? {};
    final remoteFrozen =
        (rs['frozenDates'] as List<dynamic>?)?.cast<String>().toSet() ?? {};
    final lLast = ls['lastStudiedDate'] as String?;
    final rLast = rs['lastStudiedDate'] as String?;
    final String? newerLast;
    if (lLast == null) {
      newerLast = rLast;
    } else if (rLast == null) {
      newerLast = lLast;
    } else {
      newerLast = lLast.compareTo(rLast) >= 0 ? lLast : rLast;
    }
    final mergedStreak = {
      'currentStreak': max(
        ls['currentStreak'] as int? ?? 0,
        rs['currentStreak'] as int? ?? 0,
      ),
      'freezeCount': max(
        ls['freezeCount'] as int? ?? 1,
        rs['freezeCount'] as int? ?? 1,
      ),
      'lastStudiedDate': newerLast,
      'studiedDates': {...localStudied, ...remoteStudied}.toList(),
      'frozenDates': {...localFrozen, ...remoteFrozen}.toList(),
    };

    // bookmarks: union
    final localBookmarks =
        (local['bookmarks'] as List<dynamic>?)?.cast<String>().toSet() ?? {};
    final remoteBookmarks =
        (remote['bookmarks'] as List<dynamic>?)?.cast<String>().toSet() ?? {};

    return {
      'learningHistory': mergedHistory,
      'dailyStudyLogs': logsByDate.values.toList(),
      'streak': mergedStreak,
      'bookmarks': {...localBookmarks, ...remoteBookmarks}.toList(),
    };
  }
}
