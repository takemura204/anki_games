import 'dart:async';

import 'package:core/features/exam_quiz/auth/auth_user_provider.dart';
import 'package:core/features/exam_quiz/profile/model/user_profile.dart';
import 'package:core/features/exam_quiz/profile/repository/firestore_profile_repository.dart';
import 'package:core/features/exam_quiz/profile/repository/profile_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final profileViewModelProvider =
    AsyncNotifierProvider<ProfileViewModel, UserProfile>(
  ProfileViewModel.new,
);

class ProfileViewModel extends AsyncNotifier<UserProfile> {
  final _repo = ProfileRepository();
  final _firestoreRepo = FirestoreProfileRepository();

  bool get _shouldSync => ref.read(isSyncEnabledProvider);

  @override
  Future<UserProfile> build() => _repo.load();

  Future<void> updateDisplayName(String name) async {
    final current = state.asData?.value ?? const UserProfile();
    final updated = current.copyWith(
      displayName: name.trim().isEmpty ? null : name.trim(),
    );
    await _repo.save(updated);
    state = AsyncData(updated);
    if (_shouldSync) unawaited(_firestoreRepo.save(updated).catchError((_) {}));
  }

  Future<void> updateGender(Gender gender) async {
    final current = state.asData?.value ?? const UserProfile();
    final updated = current.copyWith(gender: gender);
    await _repo.save(updated);
    state = AsyncData(updated);
    if (_shouldSync) unawaited(_firestoreRepo.save(updated).catchError((_) {}));
  }

  Future<void> updateAgeRange(AgeRange ageRange) async {
    final current = state.asData?.value ?? const UserProfile();
    final updated = current.copyWith(ageRange: ageRange);
    await _repo.save(updated);
    state = AsyncData(updated);
    if (_shouldSync) unawaited(_firestoreRepo.save(updated).catchError((_) {}));
  }
}
