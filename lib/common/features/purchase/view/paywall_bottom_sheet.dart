import 'package:anki_games/common/config/constants/app_urls.dart';
import 'package:anki_games/common/features/purchase/view_model/premium_view_model.dart';
import 'package:anki_games/common/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// ペイウォールボトムシートウィジェット。
/// [ModalSheetRouter] から呼び出す。
class PaywallSheet extends HookConsumerWidget {
  const PaywallSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumViewModelProvider);
    final priceAsync = ref.watch(monthlyPriceProvider);
    final titleAsync = ref.watch(monthlyTitleProvider);
    final isPremium = premiumState.valueOrNull?.isPremium ?? false;
    final isLoading = useState(false);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            titleAsync.valueOrNull ?? t.premium.title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          if (isPremium) ...[
            _FeatureRow(
              icon: Icons.check_circle_rounded,
              label: t.premium.activeBadge,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  t.common.ok,
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ),
          ] else ...[
            _FeatureRow(
              icon: Icons.block_rounded,
              label: t.premium.featureNoAds,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _FeatureRow(
              icon: Icons.lock_open_rounded,
              label: t.premium.featureAllGenres,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading.value
                    ? null
                    : () => _onPurchase(context, ref, isLoading),
                child: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        priceAsync.when(
                          data: (String? price) => t.premium.subscribeButton(
                            price: price ?? '¥480',
                          ),
                          loading: () => '...',
                          error: (_, __) => t.premium.subscribeButton(
                            price: '¥480',
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: isLoading.value
                    ? null
                    : () => _onRestore(context, ref, isLoading),
                child: Text(
                  t.premium.restoreButton,
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(AppUrls.termsOfService),
                    mode: LaunchMode.inAppWebView,
                  ),
                  child: Text(
                    t.premium.terms,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '·',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(AppUrls.privacyPolicy),
                    mode: LaunchMode.inAppWebView,
                  ),
                  child: Text(
                    t.premium.privacy,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onPurchase(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      await ref.read(premiumViewModelProvider.notifier).purchase();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.premium.errorPurchaseFailed)),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _onRestore(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      await ref.read(premiumViewModelProvider.notifier).restore();
      final isPremium =
          ref.read(premiumViewModelProvider).valueOrNull?.isPremium ?? false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPremium
                  ? t.premium.restoreSuccess
                  : t.premium.restoreNotFound,
            ),
          ),
        );
        if (isPremium) {
          Navigator.of(context).pop();
        }
      }
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.premium.errorRestoreFailed)),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
