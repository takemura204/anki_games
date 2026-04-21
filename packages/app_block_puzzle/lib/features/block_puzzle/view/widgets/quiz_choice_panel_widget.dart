import 'package:core/features/quiz/view_model/quiz_view_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../model/game_theme.dart';
import '../../view_model/block_puzzle_view_model.dart';
import 'piece_tray_widget.dart';
import 'quiz_meta_chips_widget.dart';
import 'quiz_word_header_widget.dart';

/// 4択インラインパネル。
///
/// レイアウト: ブロック（選択前グレーアウト）→ 問題文・チップ → 2×2 選択肢ボタン。
/// ボタンをタップして選択 → ブロックがドラッグ可能になる。選択し直しも可能。
class QuizChoicePanelWidget extends ConsumerWidget {
  const QuizChoicePanelWidget({
    required this.question,
    required this.cellSize,
    required this.theme,
    super.key,
  });

  final QuizQuestion question;
  final double cellSize;
  final GameTheme theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.quizSelectedChoiceIndex),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final choices = question.choices;
    final isSelected = selectedIndex != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ブロックエリア（常時表示・選択前はグレーアウト）
        // 横幅いっぱい・最小パディング・薄い背景色
        AbsorbPointer(
          absorbing: !isSelected,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.3,
            child: ColoredBox(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: PieceTrayWidget(
                  cellSize: cellSize,
                  theme: theme,
                  trayHeight: cellSize * 2.5,
                  pieceScale: 0.40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 問題文・メタ情報
        QuizWordHeaderWidget(question: question),
        QuizMetaChipsWidget(question: question),
        const SizedBox(height: 8),

        // 2×2 選択肢ボタン
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 2 && i < choices.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child: _ChoiceButton(
                          text: choices[i].text,
                          isSelected: selectedIndex == i,
                          isDark: isDark,
                          onTap: () => ref
                              .read(blockPuzzleViewModelProvider.notifier)
                              .selectQuizChoice(i),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 2; i < 4 && i < choices.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child: _ChoiceButton(
                          text: choices[i].text,
                          isSelected: selectedIndex == i,
                          isDark: isDark,
                          onTap: () => ref
                              .read(blockPuzzleViewModelProvider.notifier)
                              .selectQuizChoice(i),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.text,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        isDark ? const Color(0xFF4FC3F7) : const Color(0xFF0288D1);
    final borderColor =
        isSelected ? selectedColor : (isDark ? Colors.white24 : Colors.black12);
    final bgColor =
        isSelected ? selectedColor.withValues(alpha: 0.15) : Colors.transparent;
    final textColor =
        isSelected ? selectedColor : (isDark ? Colors.white70 : Colors.black54);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
