import '../../domain/entities/watchlist.dart';

class WatchlistModel {
  final String id;
  final String name;
  final List<String> symbols;

  const WatchlistModel({
    required this.id,
    required this.name,
    required this.symbols,
  });

  factory WatchlistModel.fromDomain(Watchlist entity) {
    return WatchlistModel(
      id: entity.id,
      name: entity.name,
      symbols: List<String>.from(entity.symbols),
    );
  }

  Watchlist toDomain() {
    return Watchlist(
      id: id,
      name: name,
      symbols: List<String>.from(symbols),
    );
  }

  factory WatchlistModel.fromJson(Map<String, dynamic> json) {
    return WatchlistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      symbols: (json['symbols'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbols': symbols,
    };
  }
}
