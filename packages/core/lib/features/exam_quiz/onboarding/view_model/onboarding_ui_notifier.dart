import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/filter/model/quiz_filter.dart';
import 'package:core/features/exam_quiz/filter/repository/filter_repository.dart';
import 'package:core/features/exam_quiz/notification/model/notification_settings.dart';
import 'package:core/features/exam_quiz/notification/model/notification_time_slot.dart';
import 'package:core/features/exam_quiz/notification/view_model/notification_view_model.dart';
import 'package:core/features/exam_quiz/onboarding/model/study_goal.dart';
import 'package:core/features/exam_quiz/onboarding/repository/local_study_goal_repository.dart';
import 'package:core/features/purchase/model/plan_type.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_ui_notifier.g.dart';

class OnboardingUiState {
  const OnboardingUiState({
    this.selectedSystems = const {},
    this.selectedMajors = const {},
    this.expandedSystems = const {},
    this.selectedNotificationSlot,
    this.customNotificationHour,
    this.customNotificationMinute,
    this.isNotificationLoading = false,
    this.selectedPlan = PlanType.monthly,
    this.selectedGoal,
    this.isPurchaseLoading = false,
    this.quizSelectedLabel,
    this.quizIsAnswered = false,
    this.quizShowActionBar = false,
  });

  final Set<String> selectedSystems;
  final Set<String> selectedMajors;
  final Set<String> expandedSystems;
  final NotificationTimeSlot? selectedNotificationSlot;
  final int? customNotificationHour;
  final int? customNotificationMinute;
  final bool isNotificationLoading;
  final PlanType selectedPlan;
  final StudyGoal? selectedGoal;
  final bool isPurchaseLoading;
  final String? quizSelectedLabel;
  final bool quizIsAnswered;
  final bool quizShowActionBar;

  OnboardingUiState copyWith({
    Set<String>? selectedSystems,
    Set<String>? selectedMajors,
    Set<String>? expandedSystems,
    NotificationTimeSlot? selectedNotificationSlot,
    Object? customNotificationHour = _sentinel,
    Object? customNotificationMinute = _sentinel,
    bool? isNotificationLoading,
    PlanType? selectedPlan,
    Object? selectedGoal = _sentinel,
    bool? isPurchaseLoading,
    Object? quizSelectedLabel = _sentinel,
    bool? quizIsAnswered,
    bool? quizShowActionBar,
  }) {
    return OnboardingUiState(
      selectedSystems: selectedSystems ?? this.selectedSystems,
      selectedMajors: selectedMajors ?? this.selectedMajors,
      expandedSystems: expandedSystems ?? this.expandedSystems,
      selectedNotificationSlot:
          selectedNotificationSlot ?? this.selectedNotificationSlot,
      customNotificationHour: customNotificationHour == _sentinel
          ? this.customNotificationHour
          : customNotificationHour as int?,
      customNotificationMinute: customNotificationMinute == _sentinel
          ? this.customNotificationMinute
          : customNotificationMinute as int?,
      isNotificationLoading:
          isNotificationLoading ?? this.isNotificationLoading,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      selectedGoal: selectedGoal == _sentinel
          ? this.selectedGoal
          : selectedGoal as StudyGoal?,
      isPurchaseLoading: isPurchaseLoading ?? this.isPurchaseLoading,
      quizSelectedLabel: quizSelectedLabel == _sentinel
          ? this.quizSelectedLabel
          : quizSelectedLabel as String?,
      quizIsAnswered: quizIsAnswered ?? this.quizIsAnswered,
      quizShowActionBar: quizShowActionBar ?? this.quizShowActionBar,
    );
  }
}

const _sentinel = Object();

@Riverpod(keepAlive: true)
class OnboardingUiNotifier extends _$OnboardingUiNotifier {
  @override
  OnboardingUiState build() => const OnboardingUiState();

  void selectSystem(String system) {
    final majors =
        ref.read(examConfigProvider).categoryTree[system] ?? [];
    state = state.copyWith(
      selectedSystems: {...state.selectedSystems, system},
      selectedMajors: {...state.selectedMajors, ...majors},
      expandedSystems: {...state.expandedSystems, system},
    );
  }

  void deselectSystem(String system) {
    final majors =
        (ref.read(examConfigProvider).categoryTree[system] ?? []).toSet();
    state = state.copyWith(
      selectedSystems: state.selectedSystems.where((s) => s != system).toSet(),
      selectedMajors: state.selectedMajors.difference(majors),
      expandedSystems:
          state.expandedSystems.where((s) => s != system).toSet(),
    );
  }

  void toggleMajor(String major) {
    final majors = Set<String>.from(state.selectedMajors);
    if (majors.contains(major)) {
      majors.remove(major);
    } else {
      majors.add(major);
    }
    state = state.copyWith(selectedMajors: majors);
  }

  void toggleExpansion(String system) {
    final expanded = Set<String>.from(state.expandedSystems);
    if (expanded.contains(system)) {
      expanded.remove(system);
    } else {
      expanded.add(system);
    }
    state = state.copyWith(expandedSystems: expanded);
  }

  void selectNotificationSlot(NotificationTimeSlot slot) {
    state = state.copyWith(
      selectedNotificationSlot: slot,
      customNotificationHour: slot.hour,
      customNotificationMinute: slot.minute,
    );
  }

  void setCustomNotificationTime(int hour, int minute) {
    state = state.copyWith(
      customNotificationHour: hour,
      customNotificationMinute: minute,
    );
  }

  void answerQuiz(String label) {
    if (state.quizIsAnswered) return;
    state = state.copyWith(quizSelectedLabel: label, quizIsAnswered: true);
  }

  void showQuizActionBar() {
    state = state.copyWith(quizShowActionBar: true);
  }

  void selectPlan(PlanType plan) {
    state = state.copyWith(selectedPlan: plan);
  }

  /// 学習期間目標を選択し、推奨プランを pre-select する。
  void selectGoal(StudyGoal goal) {
    state = state.copyWith(
      selectedGoal: goal,
      selectedPlan: goal.recommendedPlan,
    );
  }

  /// 学習期間目標を保存する。
  Future<void> submitGoal() async {
    final goal = state.selectedGoal;
    if (goal == null) return;
    await ref.read(studyGoalRepositoryProvider).saveGoal(goal);
  }

  void setNotificationLoading({required bool loading}) {
    state = state.copyWith(isNotificationLoading: loading);
  }

  void setPurchaseLoading({required bool loading}) {
    state = state.copyWith(isPurchaseLoading: loading);
  }

  void reset() => state = const OnboardingUiState();

  /// 選択済みのシステム・科目をフィルターとして保存する。
  void submitCategory() {
    if (state.selectedSystems.isEmpty) return;
    final examConfig = ref.read(examConfigProvider);
    ref
        .read(filterRepositoryProvider)
        .save(
          QuizFilter(
            selectedEraIds: examConfig.examList.map((m) => m.eraId).toSet(),
            selectedSystems: state.selectedSystems,
            selectedMajors: state.selectedMajors,
          ),
        )
        .ignore();
  }

  /// 通知設定を保存してローディングを解除する。
  Future<void> saveNotificationSettings({required bool granted}) async {
    final ob = state;
    if (ob.customNotificationHour != null &&
        ob.customNotificationMinute != null) {
      await ref
          .read(notificationViewModelProvider.notifier)
          .saveSettings(
            NotificationSettings(
              enabled: granted,
              hour: ob.customNotificationHour,
              minute: ob.customNotificationMinute,
            ),
          );
    }
    setNotificationLoading(loading: false);
  }

  /// プレミアム購入を実行し、プレミアムになったかどうかを返す。
  ///
  /// セール Offering で購入する（オンボーディング中はセール価格）。
  Future<bool> submitPurchase() async {
    if (kDebugMode) {
      ref.read(premiumViewModelProvider.notifier).debugSetPremium();
      return true;
    }
    setPurchaseLoading(loading: true);
    try {
      await ref
          .read(premiumViewModelProvider.notifier)
          .purchasePlan(state.selectedPlan, sale: true);
      return ref.read(premiumViewModelProvider).asData?.value.isPremium ??
          false;
    } finally {
      setPurchaseLoading(loading: false);
    }
  }

  /// ATT（iOS）または UMP（Android）の同意フローを実行する。
  Future<void> submitTracking() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } else {
      final completer = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          final isAvailable =
              await ConsentInformation.instance.isConsentFormAvailable();
          if (isAvailable) {
            ConsentForm.loadAndShowConsentFormIfRequired(
              (_) => completer.complete(),
            ).ignore();
          } else {
            completer.complete();
          }
        },
        (_) => completer.complete(),
      );
      await completer.future;
    }
  }
}
