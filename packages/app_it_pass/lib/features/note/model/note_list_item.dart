import '../../learning/model/learning_level.dart';
import '../../quiz/model/question.dart';

enum NoteTab { review, bookmark, history }

class NoteListItem {
  const NoteListItem({
    required this.question,
    required this.level,
    required this.isBookmarked,
    this.selectedLabel,
    this.lastWasCorrect,
  });

  final Question question;
  final LearningLevel level;
  final bool isBookmarked;

  /// 履歴タブ: ユーザーが選択した選択肢ラベル
  final String? selectedLabel;

  /// 履歴タブ: 正解したか
  final bool? lastWasCorrect;

  NoteListItem copyWith({bool? isBookmarked}) {
    return NoteListItem(
      question: question,
      level: level,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      selectedLabel: selectedLabel,
      lastWasCorrect: lastWasCorrect,
    );
  }
}
