import 'package:freezed_annotation/freezed_annotation.dart';

import '../../learning/model/learning_level.dart';
import '../../quiz/model/question.dart';

part 'note_list_item.freezed.dart';

enum NoteTab { review, bookmark, history }

@freezed
abstract class NoteListItem with _$NoteListItem {
  const factory NoteListItem({
    required Question question,
    required LearningLevel level,
    required bool isBookmarked,
    String? selectedLabel,
    bool? lastWasCorrect,
  }) = _NoteListItem;
}
