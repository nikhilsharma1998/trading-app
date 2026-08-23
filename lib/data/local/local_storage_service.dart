import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/errors/exceptions.dart';
import 'local_storage_keys.dart';

abstract class LocalStorageService {
  Future<void> init();
  dynamic get(String key);
  Future<void> put(String key, dynamic value);
  Future<void> delete(String key);
  Future<void> clear();
}

class HiveLocalStorageService implements LocalStorageService {
  Box? _box;

  @override
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      if (Hive.isBoxOpen(LocalStorageKeys.appBox)) {
        _box = Hive.box(LocalStorageKeys.appBox);
      } else {
        _box = await Hive.openBox(LocalStorageKeys.appBox);
      }
    } catch (e) {
      throw StorageException('Failed to initialize Hive local storage: $e');
    }
  }

  Box get _activeBox {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    // Attempt re-attach if box is already opened in Hive
    if (Hive.isBoxOpen(LocalStorageKeys.appBox)) {
      _box = Hive.box(LocalStorageKeys.appBox);
      return _box!;
    }
    throw const StorageException('Storage box is not initialized or closed');
  }

  @override
  dynamic get(String key) {
    try {
      final val = _activeBox.get(key);
      if (val is String && (val.startsWith('{') || val.startsWith('['))) {
        try {
          return jsonDecode(val);
        } catch (_) {
          return val;
        }
      }
      return val;
    } catch (e) {
      throw StorageException('Error reading key "$key": $e');
    }
  }

  @override
  Future<void> put(String key, dynamic value) async {
    try {
      if (value is Map || value is List) {
        await _activeBox.put(key, jsonEncode(value));
      } else {
        await _activeBox.put(key, value);
      }
    } catch (e) {
      throw StorageException('Error writing key "$key": $e');
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _activeBox.delete(key);
    } catch (e) {
      throw StorageException('Error deleting key "$key": $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _activeBox.clear();
    } catch (e) {
      throw StorageException('Error clearing storage: $e');
    }
  }
}

/// In-memory storage implementation for high-speed automated testing
class InMemoryLocalStorageService implements LocalStorageService {
  final Map<String, dynamic> _storage = {};

  @override
  Future<void> init() async {}

  @override
  dynamic get(String key) {
    final val = _storage[key];
    if (val is String && (val.startsWith('{') || val.startsWith('['))) {
      try {
        return jsonDecode(val);
      } catch (_) {
        return val;
      }
    }
    return val;
  }

  @override
  Future<void> put(String key, dynamic value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}
