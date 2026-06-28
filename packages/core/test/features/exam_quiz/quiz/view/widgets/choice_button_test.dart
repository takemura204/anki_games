import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/features/exam_quiz/model/question.dart';
import 'package:core/features/exam_quiz/quiz/view/widgets/choice_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: const [AppColorScheme.dark],
    ),
    home: Scaffold(body: child),
  );
}

const _choice = QuestionChoice(label: 'ア', text: 'テキスト選択肢', images: []);

QuizChoiceButton _button({
  String correctLabel = 'ア',
  bool isAnswered = false,
  String? selectedLabel,
  VoidCallback? onTap,
}) {
  return QuizChoiceButton(
    choice: _choice,
    questionNo: 1,
    correctLabel: correctLabel,
    isAnswered: isAnswered,
    selectedLabel: selectedLabel,
    onTap: onTap,
  );
}

void main() {
  group('QuizChoiceButton', () {
    testWidgets('未回答のとき選択肢テキストが表示される', (tester) async {
      await tester.pumpWidget(_wrap(_button()));

      expect(find.text('ア'), findsOneWidget);
      expect(find.text('テキスト選択肢'), findsOneWidget);
    });

    testWidgets('未回答のとき正誤アイコンは表示されない', (tester) async {
      await tester.pumpWidget(_wrap(_button()));

      expect(find.byIcon(AppIcons.correct), findsNothing);
      expect(find.byIcon(AppIcons.incorrect), findsNothing);
    });

    testWidgets('未回答のときタップコールバックが呼ばれる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(_button(onTap: () => tapped = true)));

      await tester.tap(find.byType(QuizChoiceButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('正解を選択したとき正解アイコンが表示される', (tester) async {
      await tester.pumpWidget(
        _wrap(_button(
          isAnswered: true,
          selectedLabel: 'ア',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.correct), findsOneWidget);
      expect(find.byIcon(AppIcons.incorrect), findsNothing);
    });

    testWidgets('誤答を選択したとき誤答アイコンが表示される', (tester) async {
      await tester.pumpWidget(
        _wrap(_button(
          correctLabel: 'イ',
          isAnswered: true,
          selectedLabel: 'ア',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.incorrect), findsOneWidget);
    });

    testWidgets('回答済みのときタップしてもコールバックは呼ばれない', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(_button(
          isAnswered: true,
          selectedLabel: 'ア',
          onTap: () => tapped = true,
        )),
      );

      await tester.tap(find.byType(QuizChoiceButton));
      await tester.pump();

      expect(tapped, isFalse);
    });
  });
}
