import 'package:app_it_pass/features/filter/view/filter_sheet.dart';
import 'package:core/utils/router/router_constants.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/note/view/note_sheet.dart';
import '../features/quiz/model/quiz_session.dart';
import '../features/settings/view/settings_sheet.dart';

/// IT Pass のモーダルボトムシート表示を一元管理する Provider。
final modalSheetRouterProvider =
    Provider<ItPassModalSheetRouter>((ref) => ItPassModalSheetRouter());

class ItPassModalSheetRouter {
  BuildContext get _ctx => rootNavigatorKey.currentContext!;

  /// 設定シートを表示する。
  Future<bool?> showSettings() async {
    return await showModalBottomSheet<bool>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SettingsSheet(),
    );
  }

  /// クイズフィルターシートを表示する。
  Future<bool?> showFilterSheet() async {
    return await showModalBottomSheet<bool>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FilterSheet(),
    );
  }

  /// 復習ノートシートを表示する。
  Future<void> showNoteSheet(QuizSession session) async {
    await showModalBottomSheet<void>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NoteSheet(session: session),
    );
  }
}
