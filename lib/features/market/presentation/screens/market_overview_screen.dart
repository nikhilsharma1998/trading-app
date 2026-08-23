import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/stock_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/repositories/market_repository.dart';
import '../providers/market_feed_provider.dart';
import '../widgets/market_stock_tile.dart';

class MarketOverviewScreen extends ConsumerStatefulWidget {
  final void Function(String symbol)? onStockSelected;

  const MarketOverviewScreen({
    super.key,
    this.onStockSelected,
  });

  @override
  ConsumerState<MarketOverviewScreen> createState() =>
      _MarketOverviewScreenState();
}

class _MarketOverviewScreenState extends ConsumerState<MarketOverviewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speed = ref.watch(marketFeedSpeedProvider);

    // Filter stocks by symbol or company name
    final allSymbols = StockConstants.allSymbols;
    final filteredSymbols = allSymbols.where((symbol) {
      if (_searchQuery.isEmpty) return true;
      final name = StockConstants.companyNames[symbol] ?? '';
      return symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Market Overview',
        showLiveBadge: true,
        showSpeedToggle: true,
      ),
      body: Column(
        children: [
          // Market status and speed indicator banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.show_chart, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${allSymbols.length} NIFTY Instruments',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: speed == MarketFeedSpeed.stress
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: speed == MarketFeedSpeed.stress
                          ? AppColors.warning.withValues(alpha: 0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    speed == MarketFeedSpeed.stress ? '50 ticks/sec' : '10 ticks/sec',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: speed == MarketFeedSpeed.stress
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search stocks (e.g. RELIANCE, TCS)...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const Divider(height: 1),

          // Stock List
          Expanded(
            child: filteredSymbols.isEmpty
                ? EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No stocks found',
                    description: 'No instruments match "$_searchQuery".',
                  )
                : ListView.separated(
                    itemCount: filteredSymbols.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final symbol = filteredSymbols[index];
                      return MarketStockTile(
                        key: ValueKey('market_tile_$symbol'),
                        symbol: symbol,
                        onTap: () {
                          if (widget.onStockSelected != null) {
                            widget.onStockSelected!(symbol);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
