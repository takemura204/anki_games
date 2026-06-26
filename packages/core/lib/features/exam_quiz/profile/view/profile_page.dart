import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/components/modal_handle.dart';
import 'package:core/config/brand/it_pass_color_scheme.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/profile/router/profile_modal_router.dart';
import 'package:core/features/exam_quiz/profile/view_model/profile_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

part 'widgets/profile_field_row.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final profileAsync = ref.watch(profileViewModelProvider);
    final notifier = ref.read(profileViewModelProvider.notifier);
    final router = ref.read(profileModalRouterProvider);

    final isEditingName = useState(false);
    final nameController = useTextEditingController(
      text: profileAsync.asData?.value.displayName ?? '',
    );
    final focusNode = useFocusNode();
    final authSnapshot = useStream(FirebaseAuth.instance.authStateChanges());
    final user = authSnapshot.data;
    final isLinked = user != null && user.providerData.isNotEmpty;
    final providerEmail = user?.email ?? user?.providerData.firstOrNull?.email;
    final providerId = user?.providerData.firstOrNull?.providerId;

    useEffect(() {
      if (isEditingName.value) focusNode.requestFocus();
      return null;
    }, [isEditingName.value]);

    useEffect(() {
      if (!isEditingName.value) {
        final name = profileAsync.asData?.value.displayName ?? '';
        if (nameController.text != name) nameController.text = name;
      }
      return null;
    }, [profileAsync.asData?.value.displayName]);

    return Column(
      children: [
        const ModalHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              GlassButton(
                cardRadius: AppBorderRadius.circle,
                child: IconButton(
                  icon: Icon(AppIcons.back, color: c.fgShade400),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.profile, color: c.fgShade400),
                    const Gap(AppSpacing.xs),
                    Text(
                      'プロフィール',
                      textAlign: TextAlign.center,
                      style: AppTextStyle.titleMedium.copyWith(
                        color: c.fgShade400,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.xxl),
            ],
          ),
        ),
        const Gap(AppSpacing.md),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              const Gap(AppSpacing.sm),
              GlassContainer(
                cardRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    _buildNameRow(
                      context,
                      c,
                      isEditingName,
                      nameController,
                      focusNode,
                      notifier,
                    ),
                    _Divider(c),
                    _ProfileFieldRow(
                      label: '性別',
                      value: profileAsync.asData?.value.gender?.label,
                      onTap: () async {
                        final result = await router.showGenderPicker(
                          profileAsync.asData?.value.gender,
                        );
                        if (result != null) await notifier.updateGender(result);
                      },
                    ),
                    _Divider(c),
                    _ProfileFieldRow(
                      label: '年齢',
                      value: profileAsync.asData?.value.ageRange?.label,
                      onTap: () async {
                        final result = await router.showAgeRangePicker(
                          profileAsync.asData?.value.ageRange,
                        );
                        if (result != null) {
                          await notifier.updateAgeRange(result);
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (!isLinked) ...[
                const Gap(AppSpacing.md),
                GlassContainer(
                  cardRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _AccountLinkRow(onTap: router.showAuthLink),
                ),
              ],
              if (isLinked) ...[
                const Gap(AppSpacing.md),
                _ProfileInfoCard(
                  uid: user.uid,
                  email: providerEmail,
                  providerId: providerId,
                ),
                const Gap(AppSpacing.md),
                _LogoutButton(onTap: () => _logout(router)),
                const Gap(AppSpacing.xs),
                _DeleteAccountButton(
                  onTap: () => _deleteAccount(context, router, user),
                ),
              ],
              const Gap(AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameRow(
    BuildContext context,
    ItPassColorScheme c,
    ValueNotifier<bool> isEditing,
    TextEditingController controller,
    FocusNode focusNode,
    ProfileViewModel notifier,
  ) {
    if (isEditing.value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLength: 10,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
                decoration: InputDecoration(
                  hintText: 'ユーザー名を入力（10文字以内）',
                  hintStyle: AppTextStyle.bodyMedium.copyWith(
                    color: c.fgShade200,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                onSubmitted: (v) async {
                  await notifier.updateDisplayName(v);
                  isEditing.value = false;
                },
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.check_rounded,
                size: 20,
                color: ItPassColors.seed,
              ),
              onPressed: () async {
                await notifier.updateDisplayName(controller.text);
                isEditing.value = false;
              },
            ),
          ],
        ),
      );
    }
    return _ProfileFieldRow(
      label: 'ユーザー名',
      value: controller.text.isEmpty ? null : controller.text,
      placeholder: '未入力',
      onTap: () => isEditing.value = true,
    );
  }

  Future<void> _logout(ProfileModalRouter router) async {
    final confirmed = await router.showLogoutConfirm();
    if (!confirmed) return;
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _deleteAccount(
    BuildContext context,
    ProfileModalRouter router,
    User? user,
  ) async {
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final providerId = user.providerData.firstOrNull?.providerId;

    final confirmed = await router.showDeleteAccountConfirm();
    if (!confirmed) return;

    try {
      if (providerId == 'google.com') {
        await _reauthWithGoogle(user);
      } else if (providerId == 'apple.com') {
        await _reauthWithApple(user);
      }

      final firestore = FirebaseFirestore.instance;
      final uid = user.uid;
      await Future.wait([
        firestore
            .collection('users')
            .doc(uid)
            .collection('backups')
            .doc('latest')
            .delete(),
        firestore.collection('users').doc(uid).delete(),
      ]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await user.delete();

      if (providerId == 'google.com') {
        await GoogleSignIn().signOut();
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('アカウントを削除しました')),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Apple 認証に失敗しました')),
        );
      }
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('認証エラー: ${e.message}')),
      );
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  Future<void> _reauthWithGoogle(User user) async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    await googleSignIn.signOut();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _reauthWithApple(User user) async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    await user.reauthenticateWithCredential(oauthCredential);
  }
}

class _AccountLinkRow extends StatelessWidget {
  const _AccountLinkRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap.withHaptic(),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Text(
              'アカウント連携',
              style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
            ),
            const Spacer(),
            Text(
              '未連携',
              style: AppTextStyle.bodySmall.copyWith(color: c.fgShade300),
            ),
            const Gap(AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.fgShade300),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends HookWidget {
  const _ProfileInfoCard({
    required this.uid,
    required this.email,
    required this.providerId,
  });

  final String uid;
  final String? email;
  final String? providerId;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final showCopied = useState(false);

    return Stack(
      children: [
        GlassContainer(
          cardRadius: AppBorderRadius.md,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ProviderIcon(providerId: providerId),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email ?? '連携済み',
                          style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          uid,
                          style: AppTextStyle.labelMedium.copyWith(
                            color: c.fgShade300,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(width: 1, color: c.border1),
                  const Gap(AppSpacing.md),
                  GestureDetector(
                    onTap: () async {
                      Haptics.of(HapticType.selection).ignore();
                      await Clipboard.setData(
                        ClipboardData(text: '${email ?? ''}\n$uid'),
                      );
                      showCopied.value = true;
                      await Future<void>.delayed(const Duration(milliseconds: 800));
                      showCopied.value = false;
                    },
                    child: Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: c.fgShade300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: showCopied.value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: ClipRRect(
                borderRadius: AppBorderRadius.md,
                child: ColoredBox(
                  color: ItPassColors.bgStart.withValues(alpha: 0.7),
                  child: Center(
                    child: Text(
                      'コピーしました',
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Google "G" logo SVG
const _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.providerId});

  final String? providerId;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    if (providerId == 'google.com') {
      return SvgPicture.string(_googleLogoSvg, width: 16, height: 16);
    }
    if (providerId == 'apple.com') {
      return Icon(Icons.apple_rounded, size: 16, color: c.fg);
    }
    return const SizedBox.shrink();
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassContainer(
      cardRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap.withHaptic(HapticType.medium),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: c.fg),
              const Gap(AppSpacing.xs),
              Text(
                'ログアウト',
                style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap.withHaptic(HapticType.medium),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.red,
            ),
            const Gap(AppSpacing.xs),
            Text(
              'アカウント削除',
              style: AppTextStyle.bodyMedium.copyWith(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.c);
  final ItPassColorScheme c;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Divider(height: 1, thickness: 0.5, color: colors.border1);
  }
}
