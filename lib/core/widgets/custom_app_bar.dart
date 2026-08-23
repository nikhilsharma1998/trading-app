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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSpeed = ref.watch(marketFeedSpeedProvider);

    return AppBar(
      leading: leading,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showLiveBadge) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3, backgroundColor: AppColors.green),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                      letterSpacing: 0.6,
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
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              avatar: Icon(
                currentSpeed == MarketFeedSpeed.stress
                    ? Icons.bolt
                    : Icons.speed,
                size: 15,
                color: currentSpeed == MarketFeedSpeed.stress
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
              label: Text(
                currentSpeed == MarketFeedSpeed.stress ? '5x Stress' : '1x Normal',
                style: TextStyle(
                  fontSize: 11,
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
              padding: const EdgeInsets.symmetric(horizontal: 2),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                ref.read(marketFeedSpeedProvider.notifier).toggleSpeed();
              },
            ),
          ),
        ],
        ...?actions,

        const SizedBox(width: 8),
      ],
    );
  }
}
