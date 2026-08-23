import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class PortfolioScreen extends StatelessWidget {
  final void Function(String symbol)? onStockSelected;

  const PortfolioScreen({
    super.key,
    this.onStockSelected,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Portfolio & Holdings',
      ),
      body: Center(
        child: Text('Portfolio Screen'),
      ),
    );
  }
}
