import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repository/onboarding_repository.dart';

part 'onboarding_view_model.g.dart';

@Riverpod(keepAlive: true)
class OnboardingViewModel extends _$OnboardingViewModel {
  final _repo = OnboardingRepository();

  @override
  Future<bool> build() => _repo.isCompleted();

  Future<void> complete() async {
    await _repo.markCompleted();
    state = const AsyncData(true);
  }

  Future<void> reset() async {
    await _repo.reset();
    state = const AsyncData(false);
  }
}
