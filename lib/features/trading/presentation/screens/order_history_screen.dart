import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Order History',
        showSpeedToggle: false,
      ),
      body: Center(
        child: Text('Order History Screen'),
      ),
    );
  }
}
