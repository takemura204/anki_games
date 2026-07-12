import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_user_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<User?> authUser(Ref ref) => FirebaseAuth.instance.authStateChanges();

@Riverpod(keepAlive: true)
bool isSyncEnabled(Ref ref) {
  final isPremium =
      ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false;
  final user = ref.watch(authUserProvider).asData?.value;
  return isPremium && (user?.providerData.isNotEmpty ?? false);
}
