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

    return watchlistsAsync.when(
      data: (watchlists) {
        if (watchlists.isEmpty) {
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
            body: EmptyStateView(
              icon: Icons.format_list_bulleted,
              title: 'No watchlists found',
              description: 'Create a watchlist to start monitoring your selected stocks.',
              actionLabel: 'Create Watchlist',
              onAction: () => _showCreateDialog(context, ref),
            ),
          );
        }

        final activeWatchlist = watchlists.firstWhere(
          (w) => w.id == activeId,
          orElse: () => watchlists.first,
        );

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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                tooltip: 'Watchlist Options',
                color: AppColors.surfaceElevated,
                onSelected: (value) {
                  if (value == 'manage') {
                    _showEditDialog(
                      context,
                      ref,
                      activeWatchlist,
                      watchlists.length > 1,
                    );
                  } else if (value == 'new') {
                    _showCreateDialog(context, ref);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'manage',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Edit "${activeWatchlist.name}"',
                            style: const TextStyle(color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'new',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Create New Watchlist', style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
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
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (isSelected) {
                              _showEditDialog(
                                context,
                                ref,
                                wl,
                                watchlists.length > 1,
                              );
                            } else {
                              ref.read(activeWatchlistIdProvider.notifier).state = wl.id;
                            }
                          },
                          onLongPress: () {
                            _showEditDialog(
                              context,
                              ref,
                              wl,
                              watchlists.length > 1,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.only(
                              left: 14,
                              right: isSelected ? 4 : 14,
                              top: 6,
                              bottom: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    wl.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 2),
                                  InkResponse(
                                    radius: 16,
                                    onTap: () => _showEditDialog(
                                      context,
                                      ref,
                                      wl,
                                      watchlists.length > 1,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.more_vert,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Active Watchlist Summary & Action Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.background,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              activeWatchlist.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '${activeWatchlist.symbols.length} STOCKS',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dedicated Edit / Rename / Delete button
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                      tooltip: 'Rename or Delete Watchlist',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showEditDialog(
                        context,
                        ref,
                        activeWatchlist,
                        watchlists.length > 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Add Stock button
                    ElevatedButton.icon(
                      onPressed: () => _showStockPicker(context, ref, activeWatchlist),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Add Stock',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
          ),
        );
      },
      loading: () => Scaffold(
        appBar: const CustomAppBar(title: 'Watchlists', showLiveBadge: true, showSpeedToggle: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: const CustomAppBar(title: 'Watchlists', showLiveBadge: true, showSpeedToggle: true),
        body: Center(
          child: Text(
            'Failed to load watchlists: $err',
            style: const TextStyle(color: AppColors.red),
          ),
        ),
      ),
    );
  }
}
