import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:anki_games/common/features/settings/view_model/settings_view_model.dart';
import 'package:anki_games/common/until/service/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// クイズ問題文とTTSアイコンを横並びで表示するヘッダー。
class QuizWordHeaderWidget extends ConsumerWidget {
  const QuizWordHeaderWidget({required this.question, super.key});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ttsEnabled =
        ref.watch(settingsViewModelProvider.select((s) => s.ttsEnabled));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (question.format == QuizFormat.enToJaChoice && ttsEnabled) ...[
            GestureDetector(
              onTap: () => TtsService.instance.speak(question.word.en),
              child: Icon(
                Icons.volume_up_rounded,
                size: 20,
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              question.displayText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
