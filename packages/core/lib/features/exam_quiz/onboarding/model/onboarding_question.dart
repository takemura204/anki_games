import 'package:core/features/exam_quiz/model/question.dart';

const kOnboardingQuestion = Question(
  eraId: 'tutorial',
  no: 0,
  title: '',
  body: QuestionBody(
    text: '"IT" は何の略称ですか。',
    subItems: [],
    images: [],
  ),
  choices: [
    QuestionChoice(label: 'ア', text: 'Information Technology', images: []),
    QuestionChoice(label: 'イ', text: 'Internet Technology', images: []),
    QuestionChoice(label: 'ウ', text: 'Intelligent Terminal', images: []),
    QuestionChoice(label: 'エ', text: 'Integrated Technology', images: []),
  ],
  answer: 'ア',
  explanationText:
      '「IT」は Information Technology（情報技術）の略称です。'
      'ITパスポート試験では、ITの基礎から企業・社会での活用まで幅広く出題されます。',
  explanationImages: [],
  explanationChoiceComments: [],
  categoryRaw: '',
  system: 'テクノロジ系',
  major: '',
  minor: '',
);
