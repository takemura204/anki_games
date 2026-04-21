import 'package:core/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'router_constants.dart';

/// ダイアログの表示を一元管理する Provider。
/// ViewModel から context 不要で呼び出せる。
final modalRouterProvider = Provider<ModalRouter>((ref) => ModalRouter());

class ModalRouter {
  BuildContext get _ctx => rootNavigatorKey.currentContext!;

  /// 学習データ削除の確認ダイアログを表示し、ユーザーの選択を返す。
  Future<bool> showDeleteLearningDataConfirm() async {
    final result = await showDialog<bool>(
      context: _ctx,
      builder: (ctx) {
        final translations = Translations.of(ctx);
        return AlertDialog(
          title: Text(translations.settings.deleteLearningDataConfirmTitle),
          content: Text(translations.settings.deleteLearningDataConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(translations.settings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(translations.settings.deleteLearningDataConfirm),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
