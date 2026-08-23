import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/stock_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/price_flash_container.dart';
import '../../../market/presentation/providers/market_feed_provider.dart';

class WatchlistStockRow extends ConsumerWidget {
  final String symbol;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const WatchlistStockRow({
    super.key,
    required this.symbol,
    required this.index,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fine-grained selector for only this symbol's tick
    final tick = ref.watch(stockTickProvider(symbol));
    final companyName = StockConstants.companyNames[symbol] ?? symbol;
    final isPositive = tick.change.paise >= 0;
    final changeColor = isPositive ? AppColors.green : AppColors.red;

    return PriceFlashContainer(
      tick: tick,
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Reorder drag icon
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),

                // Stock Symbol & Company Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Live LTP & Statistics
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(tick.currentPrice),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Formatters.formatCurrency(tick.change, includeSign: true),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${Formatters.formatPercentage(tick.changePercentage, includeSign: true)})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (onRemove != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.textMuted),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove from watchlist',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
