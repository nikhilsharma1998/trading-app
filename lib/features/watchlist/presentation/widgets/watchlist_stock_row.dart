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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.6),
            ),
          ),
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

              // Stock Symbol & Company Name (Clean & static)
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

              // Localized Price Badge: ONLY this small cell flashes on price ticks
              PriceFlashContainer(
                tick: tick,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          size: 14,
                          color: changeColor,
                        ),
                        Text(
                          Formatters.formatCurrency(tick.change, includeSign: true),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '(${Formatters.formatPercentage(tick.changePercentage, includeSign: true)})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remove button
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                  tooltip: 'Remove from Watchlist',
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
