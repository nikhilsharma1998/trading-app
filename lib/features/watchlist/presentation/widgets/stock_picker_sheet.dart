import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/stock_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../market/presentation/providers/market_feed_provider.dart';

class StockPickerSheet extends ConsumerStatefulWidget {
  final List<String> currentSymbols;
  final void Function(String symbol) onStockSelected;

  const StockPickerSheet({
    super.key,
    required this.currentSymbols,
    required this.onStockSelected,
  });

  @override
  ConsumerState<StockPickerSheet> createState() => _StockPickerSheetState();
}

class _StockPickerSheetState extends ConsumerState<StockPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Set<String> _addedSymbols;

  @override
  void initState() {
    super.initState();
    _addedSymbols = Set<String>.from(widget.currentSymbols);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSymbols = StockConstants.allSymbols;
    final filtered = allSymbols.where((symbol) {
      if (_searchQuery.isEmpty) return true;
      final name = StockConstants.companyNames[symbol] ?? '';
      return symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Add Stocks to Watchlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search stocks (e.g. RELIANCE, TCS)...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          const Divider(height: 1),

          // Stock List or Empty State
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No stocks found',
                    description: _searchQuery.isNotEmpty
                        ? 'No instruments match "$_searchQuery".'
                        : 'No available stocks to display.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final symbol = filtered[index];
                      final companyName = StockConstants.companyNames[symbol] ?? symbol;
                      final isAdded = _addedSymbols.contains(symbol);
                      final tick = ref.watch(stockTickProvider(symbol));

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Row(
                          children: [
                            Text(
                              symbol,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Formatters.formatCurrency(tick.currentPrice),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        trailing: isAdded
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.greenLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 14, color: AppColors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Added',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _addedSymbols.add(symbol);
                                  });
                                  widget.onStockSelected(symbol);
                                },
                                child: const Text('Add', style: TextStyle(fontSize: 12)),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
