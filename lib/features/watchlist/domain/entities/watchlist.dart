/// Immutable entity representing a user's stock watchlist
class Watchlist {
  final String id;
  final String name;
  final List<String> symbols;

  const Watchlist({
    required this.id,
    required this.name,
    required this.symbols,
  });

  Watchlist copyWith({
    String? id,
    String? name,
    List<String>? symbols,
  }) {
    return Watchlist(
      id: id ?? this.id,
      name: name ?? this.name,
      symbols: symbols ?? List.unmodifiable(this.symbols),
    );
  }

  bool containsSymbol(String symbol) => symbols.contains(symbol);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Watchlist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          _listEquals(symbols, other.symbols);

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ symbols.length.hashCode;

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
