import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../core/strings.dart';
import '../data/api_client.dart';
import '../data/lifeshare_api.dart';
import '../data/mock_api.dart';
import '../data/remote_api.dart';
import '../models/models.dart';

/// App-wide state: language, session (token + user), lookups and settings.
/// Screens read it with `context.app` and rebuild when it changes.
class AppState extends ChangeNotifier {
  AppState._(this.api, this._client, this._prefs);

  final LifeShareApi api;
  final ApiClient? _client;
  final SharedPreferences _prefs;

  static const _kToken = 'token';
  static const _kLang = 'lang';
  static const _kNotif = 'notifications';
  static const _kTheme = 'theme';

  String lang = 'ar';
  String? token;
  AppUser? user;
  bool notificationsOn = true;

  /// 'system', 'light' or 'dark'.
  String themeMode = 'light';
  List<City> cities = const [];
  List<Hospital> hospitals = const [];

  /// The user's donation record (newest first). Null until loaded.
  List<Donation>? donations;

  bool get isRtl => lang == 'ar';
  bool get isLoggedIn => token != null && user != null;

  static Future<AppState> create() async {
    final prefs = await SharedPreferences.getInstance();
    ApiClient? client;
    LifeShareApi api;
    if (AppConfig.useMock) {
      api = MockApi();
    } else {
      client = ApiClient();
      api = RemoteApi(client);
    }
    final s = AppState._(api, client, prefs);
    s.lang = prefs.getString(_kLang) ?? 'ar';
    s.notificationsOn = prefs.getBool(_kNotif) ?? true;
    s.themeMode = prefs.getString(_kTheme) ?? 'light';
    s._client?.language = s.lang;
    s.token = prefs.getString(_kToken);
    s.api.setToken(s.token);
    return s;
  }

  /// Loads cities/hospitals and, when a token was saved, the signed-in user.
  /// Returns true when the user is signed in.
  Future<bool> bootstrap() async {
    try {
      final results = await Future.wait([api.getCities(), api.getHospitals()]);
      cities = results[0] as List<City>;
      hospitals = results[1] as List<Hospital>;
    } catch (_) {
      // Lookups are retried later by screens that need them.
    }
    if (token != null) {
      try {
        user = await api.me();
      } on ApiException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) await logout();
      } catch (_) {}
    }
    notifyListeners();
    return isLoggedIn;
  }

  Future<void> ensureLookups() async {
    if (cities.isNotEmpty && hospitals.isNotEmpty) return;
    final results = await Future.wait([api.getCities(), api.getHospitals()]);
    cities = results[0] as List<City>;
    hospitals = results[1] as List<Hospital>;
    notifyListeners();
  }

  // ---------- language ----------
  Future<void> setLang(String value) async {
    if (value == lang) return;
    lang = value;
    _client?.language = value;
    await _prefs.setString(_kLang, value);
    notifyListeners();
  }

  Future<void> toggleLang() => setLang(lang == 'ar' ? 'en' : 'ar');

  String t(String key, [Map<String, Object?> params = const {}]) {
    var s = kStrings[lang]?[key] ?? kStrings['ar']?[key] ?? key;
    params.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  /// Turns an error into a sentence for the user.
  String errorText(Object e) {
    if (e is ApiException) {
      switch (e.message) {
        case 'network':
          return t('errNetwork');
        case 'timeout':
          return t('errTimeout');
        case 'invalid_code':
          return t('errCode');
        case 'server':
          return t('errServer');
        default:
          return e.message; // message written by the backend
      }
    }
    return t('errServer');
  }

  // ---------- session ----------
  Future<void> setSession(AuthResult r) async {
    token = r.token;
    user = r.user;
    api.setToken(r.token);
    await _prefs.setString(_kToken, r.token);
    notifyListeners();
  }

  Future<void> refreshUser() async {
    user = await api.me();
    notifyListeners();
  }

  void setUser(AppUser u) {
    user = u;
    notifyListeners();
  }

  /// Loads (or reloads) the donation record.
  Future<void> loadDonations() async {
    donations = await api.donations();
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    user = null;
    donations = null;
    api.setToken(null);
    await _prefs.remove(_kToken);
    notifyListeners();
  }

  // ---------- settings ----------
  Future<void> setThemeMode(String mode) async {
    if (mode == themeMode) return;
    themeMode = mode;
    await _prefs.setString(_kTheme, mode);
    notifyListeners();
  }

  Future<void> setNotifications(bool on) async {
    notificationsOn = on;
    await _prefs.setBool(_kNotif, on);
    notifyListeners();
  }

  // ---------- lookup helpers ----------
  String cityName(int id) {
    for (final c in cities) {
      if (c.id == id) return c.name(lang);
    }
    return '';
  }

  String hospitalName(int id) {
    for (final h in hospitals) {
      if (h.id == id) return h.name(lang);
    }
    return '';
  }

  String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return t('justNow');
    if (diff.inMinutes < 60) return t('minAgo', {'n': diff.inMinutes});
    if (diff.inHours < 24) return t('hourAgo', {'n': diff.inHours});
    return t('dayAgo', {'n': diff.inDays});
  }
}

/// Puts [AppState] in the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget as AppScope).notifier!;
}

extension AppContext on BuildContext {
  /// Watches the app state (use inside build).
  AppState get app => AppScope.of(this);

  /// Reads the app state without rebuilding (use inside callbacks).
  AppState get appRead => AppScope.read(this);

  /// Translated text. Inside build it also rebuilds the widget when the language changes.
  String tr(String key, [Map<String, Object?> params = const {}]) =>
      AppScope.of(this).t(key, params);

  void toast(String message) {
    ScaffoldMessenger.maybeOf(this)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(milliseconds: 2400)));
  }
}
