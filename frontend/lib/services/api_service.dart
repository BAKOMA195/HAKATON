import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // URL бэкенда - CloudPub туннель
  static const String baseUrl = 'http://10.191.184.117:8001';

  static String? _token;

  // Сохранить токен
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Загрузить токен
  static Future<String?> loadToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  // Удалить токен (выход)
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Получить заголовки с токеном
  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // --- АВТОРИЗАЦИЯ ---

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        if (fullName != null) 'full_name': fullName,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username,
        'password': password,
        'grant_type': 'password',
      },
    );
    final data = _handleResponse(response);
    if (data.containsKey('access_token')) {
      await saveToken(data['access_token']);
    }
    return data;
  }

  static Future<User> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  // --- ЕЖЕДНЕВНЫЙ ВХОД ---

  static Future<DailyCheckinResult> dailyCheckin() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/daily/checkin'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return DailyCheckinResult.fromJson(data);
  }

  static Future<Map<String, dynamic>> getStreak() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/daily/streak'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // --- КВЕСТЫ ---

  static Future<List<Quest>> getDailyQuests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/quests/daily'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return (data as List).map((q) => Quest.fromJson(q)).toList();
  }

  static Future<Map<String, dynamic>> completeQuest(int questId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/quests/complete'),
      headers: _headers,
      body: jsonEncode({'quest_id': questId}),
    );
    return _handleResponse(response);
  }

  // --- КОЛЕСО ФОРТУНЫ ---

  static Future<WheelResult> spinWheel({bool useFree = true}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/wheel/spin?use_free=$useFree'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return WheelResult.fromJson(data);
  }

  static Future<Map<String, dynamic>> getSpinsInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/wheel/spins-info'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getWheelProbabilities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/wheel/probabilities'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // --- КАТАЛОГ ПРИЗОВ ---

  static Future<List<Prize>> getPrizes({String? category}) async {
    String url = '$baseUrl/api/marketplace/prizes';
    if (category != null) url += '?category=$category';
    final response = await http.get(Uri.parse(url), headers: _headers);
    final data = _handleResponse(response);
    return (data as List).map((p) => Prize.fromJson(p)).toList();
  }

  static Future<Map<String, dynamic>> redeemPrize(int prizeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/marketplace/redeem'),
      headers: _headers,
      body: jsonEncode({'prize_id': prizeId}),
    );
    return _handleResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getMyRedemptions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/marketplace/my-redemptions'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  // --- ЛИДЕРБОРД ---

  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/leaderboard'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return (data as List)
        .map((e) => LeaderboardEntry.fromJson(e))
        .toList();
  }

  static Future<List<Achievement>> getAchievements() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/achievements'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return (data as List).map((a) => Achievement.fromJson(a)).toList();
  }

  static Future<Map<String, dynamic>> getMyLeague() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/my-league'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // --- ОБРАБОТКА ОТВЕТОВ ---

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      String message = 'Ошибка сервера';
      try {
        final data = jsonDecode(response.body);
        message = data['detail'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }
}
