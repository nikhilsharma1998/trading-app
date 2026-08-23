import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/holdings/presentation/screens/portfolio_screen.dart';
import '../../features/market/presentation/screens/market_overview_screen.dart';
import '../../features/trading/presentation/screens/order_history_screen.dart';
import '../../features/watchlist/presentation/screens/watchlist_screen.dart';

/// Provider holding the currently selected bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Main shell containing the 4 primary application tabs
class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      MarketOverviewScreen(
        onStockSelected: (symbol) {
          // Will navigate to Buy/Sell ticket in Phase 7
        },
      ),
      WatchlistScreen(
        onStockSelected: (symbol) {
          // Will navigate to Buy/Sell ticket in Phase 7
        },
      ),
      PortfolioScreen(
        onStockSelected: (symbol) {
          // Will navigate to Buy/Sell ticket in Phase 7
        },
      ),
      const OrderHistoryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_outlined),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Watchlists',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
