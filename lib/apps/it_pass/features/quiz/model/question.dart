List<String> _parseImages(Map<String, dynamic> json) {
  final imgs = json['images'] as List<dynamic>?;
  if (imgs == null) {
    return [];
  }
  return imgs.map((e) => e as String).where((s) => s.isNotEmpty).toList();
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
    required this.no,
    required this.title,
    required this.body,
    required this.choices,
    required this.answer,
    required this.explanationText,
    required this.explanationImages,
    required this.categoryRaw,
    required this.system,
    required this.major,
    required this.minor,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final choicesJson = json['choices'] as List<dynamic>;
    final explanation = json['explanation'] as Map<String, dynamic>? ?? {};
    final category = json['category'] as Map<String, dynamic>? ?? {};
    return Question(
      no: json['no'] as int,
      title: json['title'] as String,
      body: QuestionBody.fromJson(json['body'] as Map<String, dynamic>),
      choices: choicesJson
          .map((e) => QuestionChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      answer: json['answer'] as String,
      explanationText: explanation['text'] as String? ?? '',
      explanationImages: _parseImages(explanation),
      categoryRaw: category['raw'] as String? ?? '',
      system: category['system'] as String? ?? '',
      major: category['major'] as String? ?? '',
      minor: category['minor'] as String? ?? '',
    );
  }

  final int no;
  final String title;
  final QuestionBody body;
  final List<QuestionChoice> choices;
  final String answer;
  final String explanationText;
  final List<String> explanationImages;
  final String categoryRaw;
  final String system;
  final String major;
  final String minor;
}
