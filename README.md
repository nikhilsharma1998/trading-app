# 📈 Real-Time High-Frequency Trading & Portfolio App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod_2.x-00C087?logoColor=white)](https://riverpod.dev)
[![Storage](https://img.shields.io/badge/Persistence-Hive_CE-FF9800?logoColor=white)](https://pub.dev/packages/hive)
[![Tests](https://img.shields.io/badge/Automated_Tests-43_Passed-00C087?logo=flutter)](https://flutter.dev)
[![Analysis](https://img.shields.io/badge/Analyzer-0_Issues-00C087)](https://dart.dev/tools/analysis)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A production-grade, real-time simulated stock trading application built with **Flutter**, **Riverpod**, and **Clean Architecture**. Engineered to handle high-frequency price feeds (up to **50+ ticks/second**) with zero frame drops, strict monetary precision via integer minor units (paise), robust offline persistence, and isolated UI rebuilds.

---

## 🌟 Key Features

### 1. ⚡ Centralized Real-Time Market Feed
- **Single Source of Truth**: Centralized singleton `MockMarketFeed` broadcasting ticks across all screens via a unified stream.
- **Bounded Random-Walk Price Engine**: Real-time tick generator with max $\pm 2.5\%$ price variance per tick and a realistic $15\%$ mean-reversion drift pull to simulate authentic market dynamics.
- **Dual Feed Speeds**:
  - **Normal Mode**: Standard simulated market (~10 ticks/second).
  - **Stress Mode**: High-frequency stress test (**50+ ticks/second**) to profile UI stability under peak volatility.
- **Directional Price Flashes**: Micro-animations flashing green (`#00C087`) on price rises and red (`#FF4D4F`) on price drops.

### 2. 📋 Watchlist Management & Reordering
- **Multiple Watchlists**: Create, rename, delete, and switch between customizable watchlists with persistent state across restarts.
- **Stock Picker**: Bottom sheet with search filter to add any of the 10 instruments (`RELIANCE`, `TCS`, `INFY`, `HDFCBANK`, `ICICIBANK`, `BHARTIARTL`, `SBIN`, `ITC`, `LT`, `TATAMOTORS`).
- **Drag-and-Drop Reordering**: Smooth drag reordering powered by `ReorderableListView.builder` with symbol-based `ValueKey` bindings.
- **Duplicate Protection**: Strict validation preventing duplicate symbols within the same watchlist.

### 3. 💹 Buy / Sell Trading Ticket & Validation
- **Real-Time LTP Calculation**: Dynamic live computation of total order value as market ticks stream in.
- **Quick Quantity Chips**: Instant allocation buttons (`+1`, `+5`, `+10`, `+25`, `Max Available`).
- **Strict Pre-Trade Validations**:
  - Rejection of non-positive / empty quantities.
  - **BUY Validation**: Immediate rejection if total order value exceeds available wallet balance.
  - **SELL Validation**: Immediate rejection if attempting to sell more shares than currently owned.
- **Dynamic Error Banners**: Contextual error messages with real-time shortfall calculations.

### 4. 📜 Order Confirmation & Persistent History
- **Post-Trade Breakdown**: Instant confirmation modal showing execution price, instrument, traded quantity, total turnover, remaining wallet balance, and remaining position.
- **Search & Filtering**: Filter order history by **All**, **Buy Orders Only**, or **Sell Orders Only**, with instant text search across symbols and order IDs.
- **Turnover Analytics**: Summary header reporting total executed orders and cumulative trading turnover (₹).

### 5. 💼 Portfolio & Live Dynamic Holdings
- **Real-Time Portfolio Aggregation**:
  - **Total Portfolio Value**: Current Market Value of all held positions + Available Cash Balance.
  - **Total Invested Amount**: $\sum (\text{Holding Quantity} \times \text{Average Buy Cost})$.
  - **Total Current Value**: $\sum (\text{Holding Quantity} \times \text{Live LTP})$.
  - **Total Unrealized P&L**: ₹ Amount and % return with live green/red profit-and-loss indicators.
  - **Day's Gain / Loss**: Dynamic aggregation of today's price movements across holdings.
- **Weighted Average Cost**: Accurate recalculation of average cost basis when accumulating additional shares on subsequent BUY orders:
  $$\text{New Average Cost} = \frac{(\text{Old Qty} \times \text{Old Avg Cost}) + (\text{Buy Qty} \times \text{Buy Price})}{\text{Old Qty} + \text{Buy Qty}}$$
- **Holdings Sorting**: Sort positions by **Current Value**, **Highest Gainers (P&L %)**, **Biggest Losers (P&L %)**, **Symbol (A-Z)**, or **Quantity**.
- **Quick Sell Navigation**: Tap any holding to immediately open the trade ticket pre-filled with the sell side.

### 6. 🛡️ Absolute Monetary Precision (Zero Floating-Point Drift)
- **Immutable `Money` Value Object**: All financial values, balances, orders, and P&L calculations are stored internally as **64-bit integer paise (minor units)**.
- Eliminates standard binary floating-point representation artifacts (e.g. `0.1 + 0.2 = 0.30000000000000004`).
- Custom Indian Lakhs & Crores currency formatting (e.g. `₹1,00,000.00`).

### 7. 🚀 High-Frequency Rebuild Isolation
- **Granular Riverpod `.select()` Providers**: `stockTickProvider(symbol)` uses selector comparisons. When `RELIANCE` ticks, **only the RELIANCE widget cell rebuilds**; adjacent sibling tiles (`TCS`, `INFY`) and parent lists do **not** rebuild.
- **Repaint Boundaries**: `PriceFlashContainer` is wrapped in a dedicated `RepaintBoundary` to isolate canvas repaint invalidations from the rest of the render tree during high-frequency price flashes.

---

## 🏛️ Architecture & Clean Code

The codebase follows **Clean Architecture** and **MVVM** principles with strict layer separation:

```
lib/
├── app/
│   ├── app.dart                        # MaterialApp root with dark theme configuration
│   ├── router/
│   │   └── app_router.dart             # Navigation shell and BottomNavigationBar (4 Tabs)
│   └── theme/
│       ├── app_colors.dart             # Dark Trading Palette (Emerald Green, Crimson Red, Obsidian)
│       └── app_theme.dart              # Material 3 dark theme specifications
│
├── core/
│   ├── constants/
│   │   └── stock_constants.dart        # 10 mandatory stocks, starting prices, ₹1,00,000 initial wallet
│   ├── money/
│   │   └── money.dart                  # Immutable integer paise Money value object with math & formatting
│   ├── utils/
│   │   └── formatters.dart             # Currency, percentage, and date/time formatters
│   └── widgets/
│       ├── custom_app_bar.dart         # Top bar with Live badge and Stress mode toggle
│       ├── empty_state_view.dart       # Reusable responsive empty state view
│       └── price_flash_container.dart  # RepaintBoundary-isolated price flash container
│
├── data/
│   ├── local/
│   │   └── local_storage_service.dart  # Hive & InMemory local storage implementations
│   └── repositories/
│       ├── holding_repository_impl.dart
│       ├── market_repository_impl.dart
│       ├── order_repository_impl.dart
│       ├── repository_providers.dart   # Riverpod providers for data repositories
│       ├── wallet_repository_impl.dart
│       └── watchlist_repository_impl.dart
│
└── features/
    ├── holdings/
    │   ├── domain/entities/
    │   │   ├── holding.dart            # Holding entity with weighted average math
    │   │   └── portfolio_summary.dart  # Portfolio statistics value object
    │   └── presentation/
    │       ├── providers/portfolio_provider.dart
    │       ├── screens/portfolio_screen.dart
    │       └── widgets/
    │           ├── holding_stock_tile.dart
    │           └── portfolio_summary_card.dart
    │
    ├── market/
    │   ├── data/
    │   │   ├── models/market_tick.dart # Immutable MarketTick model
    │   │   └── services/
    │   │       ├── mock_market_feed.dart
    │   │       └── tick_generator.dart # Bounded random-walk engine
    │   ├── domain/
    │   │   ├── entities/stock.dart
    │   │   └── repositories/market_repository.dart
    │   └── presentation/
    │       ├── providers/market_feed_provider.dart
    │       ├── screens/market_overview_screen.dart
    │       └── widgets/market_stock_tile.dart
    │
    ├── trading/
    │   ├── domain/
    │   │   ├── entities/order.dart     # Order entity (BUY/SELL)
    │   │   └── services/trading_service.dart # Atomic order execution engine
    │   └── presentation/
    │       ├── providers/
    │       │   ├── trading_provider.dart
    │       │   └── wallet_provider.dart
    │       ├── screens/
    │       │   ├── buy_sell_ticket_screen.dart
    │       │   ├── order_confirmation_screen.dart
    │       │   └── order_history_screen.dart
    │       └── widgets/order_history_tile.dart
    │
    └── watchlist/
        ├── domain/
        │   ├── entities/watchlist.dart
        │   └── repositories/watchlist_repository.dart
        └── presentation/
            ├── providers/watchlist_provider.dart
            ├── screens/watchlist_screen.dart
            └── widgets/stock_picker_sheet.dart
```

---

## 🛠️ Tech Stack & Dependencies

| Category | Package | Version | Purpose |
|---|---|---|---|
| **State Management** | `flutter_riverpod` | `^2.5.1` | Granular reactive dependency injection & selective rebuilds |
| **Local Persistence** | `hive` & `hive_flutter` | `^2.2.3` / `^1.1.0` | Fast key-value box storage for offline persistence |
| **Formatting** | `intl` | `^0.19.0` | Indian currency and date/time formatting |
| **Identifiers** | `uuid` | `^4.4.0` | Unique UUID generation for orders and watchlists |
| **Path Utility** | `path_provider` | `^2.1.2` | Application document directory resolution |

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.19.0` or higher
- **Dart SDK**: `^3.3.0` or higher
- Android Studio / VS Code with Flutter extension
- Android Device or Emulator


### Setup & Run
1. **Clone the repository**:
   ```bash
   git clone https://github.com/nikhilsharma1998/trading-app.git
   cd trading-app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Static Analysis**:
   ```bash
   flutter analyze
   ```
   *(Expected output: `No issues found!`)*

4. **Run Automated Test Suite**:
   ```bash
   flutter test
   ```
   *(Runs all 43 unit, widget, performance, and integration tests)*

5. **Launch Application**:
   ```bash
   flutter run
   ```

---

## 🧪 Comprehensive Automated Testing Strategy

The test suite contains **43 automated tests** covering every architectural layer:

```
test/
├── core/
│   └── money_test.dart
│       ├── Minor unit (paise) creation and precision arithmetic
│       ├── Multiplication without floating-point drift
│       ├── Comparison operators and equality
│       └── Indian currency (₹) & percentage formatting
│
├── data/
│   └── repositories_test.dart
│       ├── WatchlistRepository default seeding, modifications, and active ID persistence
│       ├── WalletRepository balance deductions and credits
│       ├── HoldingRepository weighted average cost updates and full position removal
│       └── OrderRepository insertion and reverse-chronological retrieval
│
├── features/
│   ├── market/
│   │   ├── market_feed_test.dart (Feed initialization, bounded ticks, speed toggle)
│   │   ├── market_overview_widget_test.dart (Stock list, search filtering, speed indicator)
│   │   └── rebuild_optimization_test.dart (Rebuild isolation profiling & Stress mode 50+ ticks/sec)
│   │
│   ├── watchlist/
│   │   ├── watchlist_manager_test.dart (CRUD, stock picker, duplicate blocking, reordering)
│   │   └── watchlist_flow_integration_test.dart (Multi-watchlist lifecycle & session persistence)
│   │
│   ├── trading/
│   │   ├── trading_engine_test.dart (Pre-trade validations, insufficient funds/shares rejection)
│   │   ├── buy_sell_ticket_widget_test.dart (Ticket rendering, live LTP calculation, quantity chips)
│   │   ├── order_history_widget_test.dart (Order history filters, search, order confirmation modal)
│   │   └── trading_flow_integration_test.dart (End-to-end multi-step buy/sell/profit realization)
│   │
│   └── holdings/
│       └── portfolio_widget_test.dart (Portfolio summary card, live P&L, sort options, empty state)
│
└── widget_test.dart
    └── TradingApp root initialization and bottom navigation smoke test
```

---

## 📊 Performance Benchmarks & Guarantees

| Metric | Guarantee | Implementation Technique |
|---|---|---|
| **Feed Throughput** | Up to 50+ ticks/sec | Asynchronous broadcast stream with buffered price store |
| **Widget Rebuilds** | Isolated to single cell | `stockTickProvider` family with Riverpod `.select()` |
| **Canvas Repainting** | Isolated during price flash | `RepaintBoundary` wrapping `PriceFlashContainer` |
| **Monetary Precision** | 0.00% calculation error | Pure integer minor units (`Money` paise class) |
| **Persistence Latency** | Sub-millisecond disk writes | Fast key-value binary storage via Hive CE |

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
