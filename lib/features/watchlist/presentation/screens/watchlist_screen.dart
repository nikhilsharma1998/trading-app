import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/entities/watchlist.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/create_watchlist_dialog.dart';
import '../widgets/edit_watchlist_dialog.dart';
import '../widgets/stock_picker_sheet.dart';
import '../widgets/watchlist_stock_row.dart';

class WatchlistScreen extends ConsumerWidget {
  final void Function(String symbol)? onStockSelected;

  const WatchlistScreen({
    super.key,
    this.onStockSelected,
  });

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => CreateWatchlistDialog(
        onCreate: (name) {
          ref.read(watchlistNotifierProvider.notifier).createWatchlist(name);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Watchlist watchlist, bool canDelete) {
    showDialog(
      context: context,
      builder: (ctx) => EditWatchlistDialog(
        watchlist: watchlist,
        canDelete: canDelete,
        onRename: (newName) {
          ref.read(watchlistNotifierProvider.notifier).renameWatchlist(watchlist.id, newName);
        },
        onDelete: () {
          ref.read(watchlistNotifierProvider.notifier).deleteWatchlist(watchlist.id);
        },
      ),
    );
  }

  void _showStockPicker(BuildContext context, WidgetRef ref, Watchlist watchlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StockPickerSheet(
        currentSymbols: watchlist.symbols,
        onStockSelected: (symbol) {
          ref.read(watchlistNotifierProvider.notifier).addStockToWatchlist(watchlist.id, symbol);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistsAsync = ref.watch(watchlistNotifierProvider);
    final activeId = ref.watch(activeWatchlistIdProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Watchlists',
        showLiveBadge: true,
        showSpeedToggle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppColors.primary),
            tooltip: 'Create Watchlist',
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: watchlistsAsync.when(
        data: (watchlists) {
          if (watchlists.isEmpty) {
            return EmptyStateView(
              icon: Icons.format_list_bulleted,
              title: 'No watchlists found',
              description: 'Create a watchlist to start monitoring your selected stocks.',
              actionLabel: 'Create Watchlist',
              onAction: () => _showCreateDialog(context, ref),
            );
          }

          final activeWatchlist = watchlists.firstWhere(
            (w) => w.id == activeId,
            orElse: () => watchlists.first,
          );

          return Column(
            children: [
              // Watchlist selector tabs
              Container(
                height: 52,
                color: AppColors.surface,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: watchlists.length + 1,
                  itemBuilder: (context, index) {
                    if (index == watchlists.length) {
                      // Add new watchlist button
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: OutlinedButton.icon(
                          onPressed: () => _showCreateDialog(context, ref),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      );
                    }

                    final wl = watchlists[index];
                    final isSelected = wl.id == activeWatchlist.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              wl.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _showEditDialog(
                                  context,
                                  ref,
                                  wl,
                                  watchlists.length > 1,
                                ),
                                child: const Icon(Icons.more_vert, size: 16, color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (selected) {
                          ref.read(activeWatchlistIdProvider.notifier).state = wl.id;
                        },
                      ),
                    );
                  },
                ),
              ),

              // Active Watchlist Summary Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.background,
                child: Row(
                  children: [
                    Text(
                      '${activeWatchlist.symbols.length} STOCKS',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showStockPicker(context, ref, activeWatchlist),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                      label: const Text(
                        'Add Stock',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Reorderable stock list or Empty state
              Expanded(
                child: activeWatchlist.symbols.isEmpty
                    ? EmptyStateView(
                        icon: Icons.bookmark_border,
                        title: 'No stocks in this watchlist',
                        description: 'Add stocks to start tracking real-time market prices.',
                        actionLabel: 'Add Stock',
                        onAction: () => _showStockPicker(context, ref, activeWatchlist),
                      )
                    : ReorderableListView.builder(
                        itemCount: activeWatchlist.symbols.length,
                        // ignore: deprecated_member_use
                        onReorder: (oldIndex, newIndex) {
                          ref.read(watchlistNotifierProvider.notifier).reorderStocks(
                                activeWatchlist.id,
                                oldIndex,
                                newIndex,
                              );
                        },

                        itemBuilder: (context, index) {
                          final symbol = activeWatchlist.symbols[index];
                          // Critical: Key based on stock symbol prevents stale binding during reordering
                          return WatchlistStockRow(
                            key: ValueKey('wl_${activeWatchlist.id}_$symbol'),
                            symbol: symbol,
                            index: index,
                            onTap: () {
                              if (onStockSelected != null) {
                                onStockSelected!(symbol);
                              }
                            },
                            onRemove: () {
                              ref.read(watchlistNotifierProvider.notifier).removeStockFromWatchlist(
                                    activeWatchlist.id,
                                    symbol,
                                  );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Text(
            'Failed to load watchlists: $err',
            style: const TextStyle(color: AppColors.red),
          ),
        ),
      ),
    );
  }
}
