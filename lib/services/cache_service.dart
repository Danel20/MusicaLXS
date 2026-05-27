import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {

  static Future<void> save(
      String key,
      dynamic value,
      ) async {

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      key,
      jsonEncode(value),
    );
  }

  static Future<dynamic> read(
      String key,
      ) async {

    final prefs =
    await SharedPreferences.getInstance();

    final data =
    prefs.getString(key);

    if (data == null) return null;

    return jsonDecode(data);
  }

  static Future<void> clear() async {

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.clear();
  }
}