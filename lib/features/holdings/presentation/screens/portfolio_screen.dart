import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/holding_stock_tile.dart';
import '../widgets/portfolio_summary_card.dart';

class PortfolioScreen extends ConsumerWidget {
  final void Function(String symbol)? onStockSelected;

  const PortfolioScreen({
    super.key,
    this.onStockSelected,
  });

  void _showSortSheet(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(holdingsSortOptionProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Sort Holdings By',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...HoldingSortOption.values.map((option) {
                final isSelected = option == currentSort;
                return ListTile(
                  title: Text(
                    option.label,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(holdingsSortOptionProvider.notifier).state = option;
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(portfolioSummaryProvider);
    final sortedHoldings = ref.watch(sortedHoldingsProvider);
    final sortOption = ref.watch(holdingsSortOptionProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Portfolio & Holdings',
        showLiveBadge: true,
        showSpeedToggle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Top Summary Card
          SliverToBoxAdapter(
            child: PortfolioSummaryCard(summary: summary),
          ),

          if (sortedHoldings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                icon: Icons.pie_chart_outline,
                title: 'No active holdings',
                description:
                    'You do not own any stocks yet. Place a BUY order in the Market or Watchlists tab to start building your simulated portfolio.',
                actionLabel: 'Explore Market',
                onAction: () {
                  ref.read(bottomNavIndexProvider.notifier).state = 0;
                },
              ),
            )
          else ...[
            // Sort & Count Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${sortedHoldings.length} POSITIONS',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showSortSheet(context, ref),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.sort, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              sortOption.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Holdings List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final holding = sortedHoldings[index];
                  return HoldingStockTile(
                    key: ValueKey('holding_${holding.symbol}'),
                    holding: holding,
                    onTap: () {
                      if (onStockSelected != null) {
                        onStockSelected!(holding.symbol);
                      }
                    },
                  );
                },
                childCount: sortedHoldings.length,
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ],
      ),
    );
  }
}
