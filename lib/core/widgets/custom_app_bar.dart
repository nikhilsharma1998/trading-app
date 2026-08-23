import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../features/market/domain/repositories/market_repository.dart';
import '../../features/market/presentation/providers/market_feed_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showLiveBadge;
  final bool showSpeedToggle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showLiveBadge = true,
    this.showSpeedToggle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSpeed = ref.watch(marketFeedSpeedProvider);

    return AppBar(
      leading: leading,
      titleSpacing: 16,
      title: Row(
        children: [
          Text(title),
          if (showLiveBadge) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3.5, backgroundColor: AppColors.green),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (showSpeedToggle) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(
                currentSpeed == MarketFeedSpeed.stress
                    ? Icons.bolt
                    : Icons.speed,
                size: 16,
                color: currentSpeed == MarketFeedSpeed.stress
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
              label: Text(
                currentSpeed == MarketFeedSpeed.stress ? '5x Stress' : '1x Normal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: currentSpeed == MarketFeedSpeed.stress
                      ? AppColors.warning
                      : AppColors.textPrimary,
                ),
              ),
              backgroundColor: currentSpeed == MarketFeedSpeed.stress
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.surfaceElevated,
              side: BorderSide(
                color: currentSpeed == MarketFeedSpeed.stress
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onPressed: () {
                ref.read(marketFeedSpeedProvider.notifier).toggleSpeed();
              },
            ),
          ),
        ],
        ...?actions,
      ],
    );
  }
}
