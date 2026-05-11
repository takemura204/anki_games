import 'dart:async';

import 'package:app_it_pass/features/profile/model/user_profile.dart';
import 'package:app_it_pass/features/profile/repository/firestore_profile_repository.dart';
import 'package:app_it_pass/features/profile/repository/profile_repository.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final profileViewModelProvider =
    AsyncNotifierProvider<ProfileViewModel, UserProfile>(
  ProfileViewModel.new,
);

class ProfileViewModel extends AsyncNotifier<UserProfile> {
  final _repo = ProfileRepository();
  final _firestoreRepo = FirestoreProfileRepository();

  bool get _shouldSync {
    final isPremium =
        ref.read(premiumViewModelProvider).asData?.value.isPremium ?? false;
    final user = FirebaseAuth.instance.currentUser;
    final isLinked = user?.providerData.isNotEmpty ?? false;
    return isPremium && isLinked;
  }

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
