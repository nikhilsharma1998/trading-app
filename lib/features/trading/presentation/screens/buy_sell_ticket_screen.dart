import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/stock_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/formatters.dart';
import '../../../market/presentation/providers/market_feed_provider.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/trade_execution_result.dart';
import '../providers/trading_provider.dart';
import '../providers/wallet_provider.dart';
import 'order_confirmation_screen.dart';


class BuySellTicketScreen extends ConsumerStatefulWidget {
  final String initialSymbol;
  final OrderSide initialSide;
  final void Function(TradeExecutionResult result)? onOrderSuccess;

  const BuySellTicketScreen({
    super.key,
    required this.initialSymbol,
    this.initialSide = OrderSide.buy,
    this.onOrderSuccess,
  });

  @override
  ConsumerState<BuySellTicketScreen> createState() => _BuySellTicketScreenState();
}

class _BuySellTicketScreenState extends ConsumerState<BuySellTicketScreen> {
  late String _selectedSymbol;
  late OrderSide _selectedSide;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  int _quantity = 1;
  String? _inlineError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSymbol = widget.initialSymbol;
    _selectedSide = widget.initialSide;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged(String value) {
    setState(() {
      final parsed = int.tryParse(value.trim());
      if (parsed == null || parsed <= 0) {
        _quantity = 0;
        _inlineError = 'Please enter a valid quantity greater than 0';
      } else {
        _quantity = parsed;
        _validateOrder();
      }
    });
  }

  void _addQuantity(int delta) {
    final newQty = (_quantity + delta).clamp(1, 100000);
    _quantityController.text = newQty.toString();
    setState(() {
      _quantity = newQty;
      _validateOrder();
    });
  }

  void _setMaxQuantity(Money ltp, Money availableBalance, int availableHoldingQty) {
    if (_selectedSide == OrderSide.buy) {
      if (ltp.paise <= 0) return;
      final maxQty = (availableBalance.paise ~/ ltp.paise).clamp(1, 100000);
      _quantityController.text = maxQty.toString();
      setState(() {
        _quantity = maxQty;
        _validateOrder();
      });
    } else {
      final maxQty = availableHoldingQty.clamp(1, 100000);
      _quantityController.text = maxQty.toString();
      setState(() {
        _quantity = maxQty;
        _validateOrder();
      });
    }
  }

  void _validateOrder() {
    _inlineError = null;
    if (_quantity <= 0) {
      _inlineError = 'Please enter a valid quantity greater than 0';
      return;
    }

    final ltp = ref.read(stockPriceProvider(_selectedSymbol));
    final projectedValue = ltp * _quantity;

    if (_selectedSide == OrderSide.buy) {
      final wallet = ref.read(walletProvider).value;
      final balance = wallet?.balance ?? Money.zero;
      if (projectedValue > balance) {
        _inlineError =
            'Insufficient balance.\nAvailable: ${balance.format()} | Required: ${projectedValue.format()}';
      }
    } else {
      final holdingQty = ref.read(stockHoldingQtyProvider(_selectedSymbol));
      if (_quantity > holdingQty) {
        _inlineError =
            'Insufficient holdings.\nYou can sell a maximum of $holdingQty shares.';
      }
    }
  }

  Future<void> _handleSubmit() async {
    _validateOrder();
    if (_inlineError != null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ref.read(tradingControllerProvider.notifier).submitOrder(
            symbol: _selectedSymbol,
            side: _selectedSide,
            quantity: _quantity,
          );

      if (mounted && result != null) {
        if (widget.onOrderSuccess != null) {
          widget.onOrderSuccess!(result);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => OrderConfirmationScreen(result: result),
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is Failure) {
            _inlineError = e.message;
          } else {
            _inlineError = 'Order execution failed: $e';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tick = ref.watch(stockTickProvider(_selectedSymbol));
    final walletAsync = ref.watch(walletProvider);
    final availableBalance = walletAsync.value?.balance ?? Money.zero;
    final availableHoldingQty = ref.watch(stockHoldingQtyProvider(_selectedSymbol));

    final isBuy = _selectedSide == OrderSide.buy;
    final themeColor = isBuy ? AppColors.green : AppColors.red;
    final projectedOrderValue = tick.currentPrice * _quantity;

    // Check validity
    final isOrderValid = _quantity > 0 &&
        _inlineError == null &&
        (isBuy
            ? projectedOrderValue <= availableBalance
            : _quantity <= availableHoldingQty);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${isBuy ? 'BUY' : 'SELL'} ORDER',
          style: TextStyle(
            color: themeColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Selector & Live LTP Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Symbol Dropdown
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSymbol,
                          dropdownColor: AppColors.surfaceElevated,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                          items: StockConstants.allSymbols.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            );
                          }).toList(),
                          onChanged: (newSymbol) {
                            if (newSymbol != null) {
                              setState(() {
                                _selectedSymbol = newSymbol;
                                _validateOrder();
                              });
                            }
                          },
                        ),
                      ),

                      // Live LTP display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatCurrency(tick.currentPrice),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Formatters.formatCurrency(tick.change, includeSign: true),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tick.change.paise >= 0 ? AppColors.green : AppColors.red,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${Formatters.formatPercentage(tick.changePercentage, includeSign: true)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tick.change.paise >= 0 ? AppColors.green : AppColors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      StockConstants.companyNames[_selectedSymbol] ?? _selectedSymbol,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // BUY / SELL Side Switcher
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSide = OrderSide.buy;
                          _validateOrder();
                        });
                      },
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isBuy ? AppColors.green : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text(
                            'BUY',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isBuy ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSide = OrderSide.sell;
                          _validateOrder();
                        });
                      },
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !isBuy ? AppColors.red : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text(
                            'SELL',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: !isBuy ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quantity Input Label & Balance Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QUANTITY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Flexible(
                  child: Text(
                    isBuy
                        ? 'Available Balance: ${availableBalance.format()}'
                        : 'Available Shares: $availableHoldingQty',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quantity Input Field
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter quantity',
                prefixIcon: Icon(Icons.tag, size: 20, color: AppColors.textSecondary),
              ),
              onChanged: _onQuantityChanged,
            ),

            const SizedBox(height: 12),

            // Quick increment chips
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('+1'),
                  onPressed: () => _addQuantity(1),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                ),
                ActionChip(
                  label: const Text('+5'),
                  onPressed: () => _addQuantity(5),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                ),
                ActionChip(
                  label: const Text('+10'),
                  onPressed: () => _addQuantity(10),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                ),
                ActionChip(
                  label: const Text('+25'),
                  onPressed: () => _addQuantity(25),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                ),
                ActionChip(
                  label: const Text('MAX'),
                  onPressed: () => _setMaxQuantity(
                    tick.currentPrice,
                    availableBalance,
                    availableHoldingQty,
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  side: const BorderSide(color: AppColors.primary),
                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Projected Order Value Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Projected Order Value',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Executed at immediate live LTP',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      Formatters.formatCurrency(projectedOrderValue),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Inline Validation Error
            if (_inlineError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _inlineError!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  disabledBackgroundColor: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (isOrderValid && !_isSubmitting) ? _handleSubmit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        '${isBuy ? 'BUY' : 'SELL'} $_selectedSymbol',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
