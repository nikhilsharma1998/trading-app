import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class WatchlistScreen extends StatelessWidget {
  final void Function(String symbol)? onStockSelected;

  const WatchlistScreen({
    super.key,
    this.onStockSelected,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Watchlists',
      ),
      body: Center(
        child: Text('Watchlist Screen'),
      ),
    );
  }
}
