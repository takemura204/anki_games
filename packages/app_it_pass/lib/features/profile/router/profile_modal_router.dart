import 'dart:io';

import 'package:app_it_pass/features/profile/model/user_profile.dart';
import 'package:app_it_pass/features/profile/view/modals/age_range_picker_modal.dart';
import 'package:app_it_pass/features/profile/view/modals/auth_link_modal.dart';
import 'package:app_it_pass/features/profile/view/modals/gender_picker_modal.dart';
import 'package:core/utils/router/router_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final profileModalRouterProvider = Provider<ProfileModalRouter>(
  (_) => ProfileModalRouter(),
);

class ProfileModalRouter {
  BuildContext get _ctx => rootNavigatorKey.currentContext!;

  Future<Gender?> showGenderPicker(Gender? current) {
    return showModalBottomSheet<Gender>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GenderPickerModal(current: current),
    );
  }

  Future<AgeRange?> showAgeRangePicker(AgeRange? current) {
    return showModalBottomSheet<AgeRange>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AgeRangePickerModal(current: current),
    );
  }

  Future<void> showAuthLink() {
    return showModalBottomSheet<void>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AuthLinkModal(),
    );
  }

  Future<bool> showLogoutConfirm() async {
    final result = await _showAdaptiveConfirmDialog(
      title: 'ログアウト',
      message: 'ログアウトしてもよろしいですか？',
      destructiveLabel: 'ログアウト',
    );
    return result ?? false;
  }

  Future<bool> showDeleteAccountConfirm() async {
    final result = await _showAdaptiveConfirmDialog(
      title: 'アカウント削除',
      message: 'アカウントとすべてのローカルデータを削除します。この操作は取り消せません。',
      destructiveLabel: '削除する',
    );
    return result ?? false;
  }

  Future<bool?> _showAdaptiveConfirmDialog({
    required String title,
    required String message,
    required String destructiveLabel,
  }) {
    final ctx = _ctx;
    if (Platform.isIOS) {
      return showCupertinoDialog<bool>(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogCtx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('キャンセル'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(destructiveLabel),
            ),
          ],
        ),
      );
    }
    return showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              destructiveLabel,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
