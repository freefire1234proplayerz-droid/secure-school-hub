import 'package:hive/hive.dart';

class LocalDb {
  static const String authBoxName = 'authBox_v2';
static const String cacheBoxName = 'cacheBox_v2';

  static late Box _authBox;
  static late Box _cacheBox;

  static Future<void> init() async {
    _authBox = await Hive.openBox(authBoxName);
    _cacheBox = await Hive.openBox(cacheBoxName);
  }

  static Future<void> saveToken(String token) async {
    await _authBox.put('jwt', token);
  }

  static String? get token => _authBox.get('jwt') as String?;

  static Future<void> saveRole(String role) async {
    await _authBox.put('role', role);
  }

  static String? get role => _authBox.get('role') as String?;

  static Future<void> saveEmail(String email) async {
    await _authBox.put('email', email);
  }

  static String? get email => _authBox.get('email') as String?;

  static bool get hasSession => token != null && token!.isNotEmpty;

  static Future<void> clearAuth() async {
    await _authBox.clear();
  }

  static Future<void> saveCache(String key, dynamic value) async {
    await _cacheBox.put(key, value);
  }

  static dynamic getCache(String key) => _cacheBox.get(key);

  static Future<void> removeCache(String key) async {
    await _cacheBox.delete(key);
  }
}
