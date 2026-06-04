import 'package:hive/hive.dart';

class LocalDb {
  static const String authBoxName = 'authBox';
  static const String cacheBoxName = 'cacheBox';

  static late Box _authBox;
  static late Box _cacheBox;

  static Future<void> init() async {
    _authBox = await Hive.openBox(authBoxName);
    _cacheBox = await Hive.openBox(cacheBoxName);
  }

  // Auth storage
  static Future<void> saveToken(String token) async {
    await _authBox.put('jwt', token);
  }

  static String? get token => _authBox.get('jwt') as String?;

  static Future<void> clearAuth() async {
    await _authBox.clear();
  }

  // Generic cache for offline sync (homework, attendance, messages etc.)
  static Future<void> saveCache(String key, dynamic value) async {
    await _cacheBox.put(key, value);
  }

  static dynamic getCache(String key) => _cacheBox.get(key);

  static Future<void> removeCache(String key) async {
    await _cacheBox.delete(key);
  }
}
