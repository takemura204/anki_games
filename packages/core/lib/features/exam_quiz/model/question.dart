List<String> _parseImages(Map<String, dynamic> json) {
  final imgs = json['images'] as List<dynamic>?;
  if (imgs == null) return [];
  return imgs.map((e) => e as String).where((s) => s.isNotEmpty).toList();
}

List<String> _parseStringList(Map<String, dynamic> json, String key) {
  final list = json[key] as List<dynamic>?;
  if (list == null) return [];
  return list.map((e) => e as String).toList();
}

class QuestionChoice {
  const QuestionChoice({
    required this.label,
    required this.text,
    required this.images,
  });

  factory QuestionChoice.fromJson(Map<String, dynamic> json) {
    return QuestionChoice(
      label: json['label'] as String,
      text: json['text'] as String,
      images: _parseImages(json),
    );
  }

  final String label;
  final String text;
  final List<String> images;
}

class QuestionBody {
  const QuestionBody({
    required this.text,
    required this.subItems,
    required this.images,
  });

  factory QuestionBody.fromJson(Map<String, dynamic> json) {
    final items = (json['sub_items'] as List<dynamic>?) ?? [];
    return QuestionBody(
      text: json['text'] as String,
      subItems: items.map((e) => e as String).toList(),
      images: _parseImages(json),
    );
  }

  final String text;
  final List<String> subItems;
  final List<String> images;
}

class Question {
  const Question({
    required this.eraId,
    required this.no,
    required this.title,
    required this.body,
    required this.choices,
    required this.answer,
    required this.explanationText,
    required this.explanationImages,
    required this.explanationChoiceComments,
    required this.categoryRaw,
    required this.system,
    required this.major,
    required this.minor,
    this.examDisplayName = '',
    this.subject,
    this.questionType,
  });

  factory Question.fromJson(
    Map<String, dynamic> json, {
    required String eraId,
    String examDisplayName = '',
  }) {
    final choicesJson = json['choices'] as List<dynamic>;
    final explanation = json['explanation'] as Map<String, dynamic>? ?? {};
    final category = json['category'] as Map<String, dynamic>? ?? {};
    return Question(
      eraId: eraId,
      no: json['no'] as int,
      title: json['title'] as String,
      body: QuestionBody.fromJson(json['body'] as Map<String, dynamic>),
      choices: choicesJson
          .map((e) => QuestionChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      answer: json['answer'] as String,
      explanationText: explanation['text'] as String? ?? '',
      explanationImages: _parseImages(explanation),
      explanationChoiceComments:
          _parseStringList(explanation, 'choice_comments'),
      categoryRaw: category['raw'] as String? ?? '',
      system: category['system'] as String? ?? '',
      major: category['major'] as String? ?? '',
      minor: category['minor'] as String? ?? '',
      examDisplayName: examDisplayName,
      subject: json['subject'] as String?,
      questionType: json['question_type'] as String?,
    );
  }

  final String eraId;
  final int no;
  final String title;
  final QuestionBody body;
  final List<QuestionChoice> choices;
  final String answer;
  final String explanationText;
  final List<String> explanationImages;
  final List<String> explanationChoiceComments;
  final String categoryRaw;
  final String system;
  final String major;
  final String minor;
  final String examDisplayName;

  /// FE 科目区分（例: '科目A', '午前'）。it_pass では null。
  final String? subject;

  /// fp3 問題タイプ（例: 'true_false', 'multiple_choice_3'）。選択式では null。
  final String? questionType;
}
