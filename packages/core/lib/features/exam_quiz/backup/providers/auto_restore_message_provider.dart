import 'package:hooks_riverpod/hooks_riverpod.dart';

class AutoRestoreMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties
  void update(String? message) => state = message;
}

final autoRestoreMessageProvider =
    NotifierProvider<AutoRestoreMessageNotifier, String?>(
  AutoRestoreMessageNotifier.new,
);
