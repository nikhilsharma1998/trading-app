import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/entities/order.dart';

import '../providers/trading_provider.dart';
import '../widgets/order_history_tile.dart';

enum OrderFilter { all, buy, sell }

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  OrderFilter _selectedFilter = OrderFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Order History',
        showLiveBadge: false,
        showSpeedToggle: false,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: 'No orders placed yet',
              description:
                  'Execute your first trade in the Market or Watchlists tab to start building your simulated portfolio.',
              actionLabel: 'Explore Market',
              onAction: () {
                ref.read(bottomNavIndexProvider.notifier).state = 0;
              },
            );
          }

          // Filter by side and search query
          final filtered = orders.where((order) {
            if (_selectedFilter == OrderFilter.buy && order.side != OrderSide.buy) {
              return false;
            }
            if (_selectedFilter == OrderFilter.sell && order.side != OrderSide.sell) {
              return false;
            }
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              return order.symbol.toLowerCase().contains(query) ||
                  order.id.toLowerCase().contains(query);
            }
            return true;
          }).toList();

          // Calculate total turnover for filtered orders
          var totalTurnoverPaise = 0;
          for (final o in filtered) {
            totalTurnoverPaise += o.totalValue.paise;
          }
          final totalTurnover = Money(totalTurnoverPaise);

          return Column(
            children: [
              // Search & Filter header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: AppColors.surface,
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search orders by symbol...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    const SizedBox(height: 10),

                    // Filter chips & Stats
                    Row(
                      children: [
                        FilterChip(
                          selected: _selectedFilter == OrderFilter.all,
                          label: const Text('All'),
                          onSelected: (_) => setState(() => _selectedFilter = OrderFilter.all),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceElevated,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _selectedFilter == OrderFilter.buy,
                          label: const Text('Buy Only'),
                          onSelected: (_) => setState(() => _selectedFilter = OrderFilter.buy),
                          selectedColor: AppColors.green,
                          backgroundColor: AppColors.surfaceElevated,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _selectedFilter == OrderFilter.sell,
                          label: const Text('Sell Only'),
                          onSelected: (_) => setState(() => _selectedFilter = OrderFilter.sell),
                          selectedColor: AppColors.red,
                          backgroundColor: AppColors.surfaceElevated,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Summary stats banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} ORDERS',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      'Turnover: ${Formatters.formatCurrency(totalTurnover)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Order List or Filtered Empty State
              Expanded(
                child: filtered.isEmpty
                    ? EmptyStateView(
                        icon: Icons.search_off,
                        title: 'No matching orders',
                        description: 'No orders match the selected filter or search query.',
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          return OrderHistoryTile(
                            key: ValueKey('order_${order.id}'),
                            order: order,
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
          child: Text('Failed to load order history: $err', style: const TextStyle(color: AppColors.red)),
        ),
      ),
    );
  }
}
