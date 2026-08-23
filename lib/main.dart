import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'data/local/local_storage_service.dart';
import 'data/repositories/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = HiveLocalStorageService();
  await storageService.init();

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storageService),
      ],
      child: const TradingApp(),
    ),
  );
}
