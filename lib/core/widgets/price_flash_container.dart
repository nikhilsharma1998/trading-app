import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../features/market/data/models/market_tick.dart';

/// Lightweight container that flashes a subtle green or red tint on price tick
/// and smoothly fades back to transparent without rebuilding its parent or child.
/// Isolated inside a RepaintBoundary to prevent repaint invalidations on surrounding elements.
class PriceFlashContainer extends StatefulWidget {
  final MarketTick tick;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const PriceFlashContainer({
    super.key,
    required this.tick,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  State<PriceFlashContainer> createState() => _PriceFlashContainerState();
}

class _PriceFlashContainerState extends State<PriceFlashContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  Color _flashColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(PriceFlashContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tick.currentPrice.paise != oldWidget.tick.currentPrice.paise) {
      if (widget.tick.direction == PriceDirection.up) {
        _triggerFlash(AppColors.greenFlash);
      } else if (widget.tick.direction == PriceDirection.down) {
        _triggerFlash(AppColors.redFlash);
      }
    }
  }

  void _triggerFlash(Color color) {
    _flashColor = color;
    _colorAnimation = ColorTween(
      begin: _flashColor,
      end: Colors.transparent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _colorAnimation.value ?? Colors.transparent,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
