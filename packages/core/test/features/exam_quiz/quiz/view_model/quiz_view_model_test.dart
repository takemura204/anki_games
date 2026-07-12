import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/daily_study_log/repository/local_daily_study_log_repository.dart';
import 'package:core/features/exam_quiz/filter/model/quiz_filter.dart';
import 'package:core/features/exam_quiz/filter/repository/filter_repository.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:core/features/exam_quiz/learning/providers/learning_history_provider.dart';
import 'package:core/features/exam_quiz/learning/repository/learning_history_repository.dart';
import 'package:core/features/exam_quiz/model/exam_meta.dart';
import 'package:core/features/exam_quiz/model/question.dart';
import 'package:core/features/exam_quiz/note/repository/local_quiz_history_repository.dart';
import 'package:core/features/exam_quiz/quiz/repository/quiz_repository.dart';
import 'package:core/features/exam_quiz/quiz/repository/quiz_resume_repository.dart';
import 'package:core/features/exam_quiz/quiz/model/quiz_session.dart';
import 'package:core/features/exam_quiz/quiz/sync/quiz_sync_notifier.dart';
import 'package:core/features/exam_quiz/quiz/view_model/quiz_view_model.dart';
import 'package:core/features/exam_quiz/streak/model/streak_data.dart';
import 'package:core/features/exam_quiz/streak/view_model/streak_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockQuizRepository extends Mock implements QuizRepository {}
class MockFilterRepository extends Mock implements FilterRepository {}
class MockLocalQuizHistoryRepository extends Mock implements LocalQuizHistoryRepository {}
class MockLocalDailyStudyLogRepository extends Mock implements LocalDailyStudyLogRepository {}
class MockQuizResumeRepository extends Mock implements QuizResumeRepository {}
class MockLearningHistoryRepository extends Mock implements LearningHistoryRepository {}
class MockExamConfig extends Mock implements ExamConfig {}



class FakeLearningHistoryNotifier extends LearningHistoryNotifier {
  FakeLearningHistoryNotifier(this.mockRepo);
  final LearningHistoryRepository mockRepo;
  @override
  Future<LearningHistoryRepository> build() async => mockRepo;
}

class FakeQuizSyncNotifier extends QuizSyncNotifier {
  @override
  Future<QuizSyncState> build() async => const QuizSyncReady();
}

class FakeStreakViewModel extends StreakViewModel {
  bool recordStudyCalled = false;
  
  @override
  StreakData build() {
    return const StreakData();
  }

  @override
  Future<void> recordStudy() async {
    recordStudyCalled = true;
  }
}

class FakeExamConfig extends Fake implements ExamConfig {}

void main() {
  late MockQuizRepository mockQuizRepo;
  late MockFilterRepository mockFilterRepo;
  late MockLocalQuizHistoryRepository mockQuizHistoryRepo;
  late MockLocalDailyStudyLogRepository mockDailyLogRepo;
  late MockQuizResumeRepository mockResumeRepo;
  late MockLearningHistoryRepository mockLearningRepo;
  late MockExamConfig mockExamConfig;
  late FakeStreakViewModel fakeStreak;
  late ProviderContainer container;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(const QuizFilter(selectedEraIds: {}));
    registerFallbackValue(FakeExamConfig());
  });

  setUp(() {
    mockQuizRepo = MockQuizRepository();
    mockFilterRepo = MockFilterRepository();
    mockQuizHistoryRepo = MockLocalQuizHistoryRepository();
    mockDailyLogRepo = MockLocalDailyStudyLogRepository();
    mockResumeRepo = MockQuizResumeRepository();
    mockLearningRepo = MockLearningHistoryRepository();
    mockExamConfig = MockExamConfig();
    fakeStreak = FakeStreakViewModel();

    when(() => mockExamConfig.examList).thenReturn([
      const ExamMeta(eraId: 'era1', displayName: 'Era 1', fileName: 'era1.json', group: ExamGroup.reiwa),
    ]);
    when(() => mockExamConfig.categoryTree).thenReturn({});
    when(() => mockExamConfig.examTypeKey).thenReturn('test_key');
    
    when(() => mockFilterRepo.load(allEraIds: any(named: 'allEraIds')))
        .thenAnswer((_) async => const QuizFilter(selectedEraIds: {'era1'}));

    when(() => mockLearningRepo.loadAll())
        .thenAnswer((_) async => <String, QuestionLearningStats>{});

    when(() => mockResumeRepo.load())
        .thenAnswer((_) async => null);
        
    when(() => mockResumeRepo.save(
          setIndex: any(named: 'setIndex'),
          questionIndex: any(named: 'questionIndex'),
          questionIds: any(named: 'questionIds'),
          filterHash: any(named: 'filterHash'),
        )).thenAnswer((_) async {});

    when(() => mockQuizRepo.loadSession(any(), any(), examConfig: any(named: 'examConfig')))
        .thenAnswer((_) async => [
              const Question(
                eraId: 'era1',
                no: 1,
                title: 'Q1',
                body: QuestionBody(text: 'body', subItems: [], images: []),
                choices: [
                  QuestionChoice(label: 'ア', text: 'A', images: []),
                  QuestionChoice(label: 'イ', text: 'B', images: []),
                ],
                answer: 'ア',
                explanationText: '',
                explanationImages: [],
                explanationChoiceComments: [],
                categoryRaw: '',
                system: '',
                major: '',
                minor: '',
              ),
              const Question(
                eraId: 'era1',
                no: 2,
                title: 'Q2',
                body: QuestionBody(text: 'body2', subItems: [], images: []),
                choices: [
                  QuestionChoice(label: 'ア', text: 'C', images: []),
                  QuestionChoice(label: 'イ', text: 'D', images: []),
                ],
                answer: 'イ',
                explanationText: '',
                explanationImages: [],
                explanationChoiceComments: [],
                categoryRaw: '',
                system: '',
                major: '',
                minor: '',
              ),
            ]);

        when(() => mockDailyLogRepo.incrementAnswered(isCorrect: any(named: 'isCorrect')))
        .thenAnswer((_) async {});
    when(() => mockQuizHistoryRepo.saveAnswer(
          eraId: any(named: 'eraId'),
          no: any(named: 'no'),
          selectedLabel: any(named: 'selectedLabel'),
          isCorrect: any(named: 'isCorrect'),
          answeredAt: any(named: 'answeredAt'),
        )).thenAnswer((_) async {});
    when(() => mockLearningRepo.recordAnswer(
          eraId: any(named: 'eraId'),
          no: any(named: 'no'),
          isCorrect: any(named: 'isCorrect'),
          at: any(named: 'at'),
          selectedLabel: any(named: 'selectedLabel'),
        )).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(mockQuizRepo),
        filterRepositoryProvider.overrideWithValue(mockFilterRepo),
        localQuizHistoryRepositoryProvider.overrideWithValue(mockQuizHistoryRepo),
        localDailyStudyLogRepositoryProvider.overrideWithValue(mockDailyLogRepo),
        quizResumeRepositoryProvider.overrideWithValue(mockResumeRepo),
        learningHistoryRepositoryProvider.overrideWith(
          () => FakeLearningHistoryNotifier(mockLearningRepo),
        ),
        examConfigProvider.overrideWithValue(mockExamConfig),
        quizSyncProvider.overrideWith(
          () => FakeQuizSyncNotifier(),
        ),
        streakViewModelProvider.overrideWith(
          () => fakeStreak,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('QuizViewModel', () {
    test('build initializes successfully and returns QuizReady', () async {
      // 1. Arrange
      final sub = container.listen(quizViewModelProvider, (_, __) {});
      final future = container.read(quizViewModelProvider.future);
      
      // 2. Act
      final state = await future;

      // 3. Assert
      expect(state, isA<QuizReady>());
      
      verify(() => mockQuizRepo.loadSession(any(), any(), examConfig: any(named: 'examConfig'))).called(1);
      sub.close();
    });

    test('answer() updates state to correct and calls repos', () async {
      // 1. Arrange
      final sub = container.listen(quizViewModelProvider, (_, __) {});
      await container.read(quizViewModelProvider.future);

      // 2. Act (正解を選ぶ)
      await container.read(quizViewModelProvider.notifier).answer('ア');

      // 3. Assert
      final state = container.read(quizViewModelProvider).value as QuizReady;
      expect(state.session.answerState, AnswerState.correct);
      expect(state.session.isAnswered, true);
      
      // レポジトリが正しく呼ばれたか
      verify(() => mockLearningRepo.recordAnswer(
            eraId: 'era1',
            no: 1,
            isCorrect: true,
            at: any(named: 'at'),
            selectedLabel: 'ア',
          )).called(1);
      verify(() => mockQuizHistoryRepo.saveAnswer(
            eraId: 'era1',
            no: 1,
            selectedLabel: 'ア',
            isCorrect: true,
            answeredAt: any(named: 'answeredAt'),
          )).called(1);
      verify(() => mockDailyLogRepo.incrementAnswered(isCorrect: true)).called(1);
      expect(fakeStreak.recordStudyCalled, true);
      sub.close();
    });

    test('nextQuestion() increments currentIndex', () async {
      // 1. Arrange
      final sub = container.listen(quizViewModelProvider, (_, __) {});
      await container.read(quizViewModelProvider.future);

      // 2. Act
      container.read(quizViewModelProvider.notifier).nextQuestion();

      // 3. Assert
      final state = container.read(quizViewModelProvider).value as QuizReady;
      expect(state.session.currentIndex, 1);
      sub.close();
    });
  });
}
