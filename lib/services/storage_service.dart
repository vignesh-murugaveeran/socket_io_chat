import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

/// Persistent storage service using SharedPreferences
/// Manages JWT token and user data caching
class StorageService extends GetxService {
  static StorageService get to => Get.find<StorageService>();

  late SharedPreferences _prefs;

  /// Initialize SharedPreferences — call in main() before runApp
  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // ─── Token Management ──────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _prefs.setString(AppConfig.tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(AppConfig.tokenKey);
  }

  bool hasToken() {
    return _prefs.containsKey(AppConfig.tokenKey) &&
        (_prefs.getString(AppConfig.tokenKey)?.isNotEmpty ?? false);
  }

  // ─── User Data ─────────────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final data = _prefs.getString(AppConfig.userKey);
    if (data == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  // ─── Clear All ─────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _prefs.remove(AppConfig.tokenKey);
    await _prefs.remove(AppConfig.userKey);
  }
}
