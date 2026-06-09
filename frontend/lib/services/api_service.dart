import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'https://constantly-purifying-skimmer.cloudpub.ru';

  static String? _token;

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> loadToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    await loadToken();
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'SKSQuest/1.0 (Android)',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Универсальный GET с обработкой ошибок
  static Future<http.Response> _get(String path) async {
    final url = '$baseUrl$path';
    developer.log('GET $url');
    try {
      final response = await http
          .get(Uri.parse(url), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));
      developer.log('Status: ${response.statusCode}');
      return response;
    } on SocketException catch (e) {
      developer.log('SocketException: $e');
      throw Exception('Нет подключения к серверу. Проверьте интернет.');
    } on HttpException catch (e) {
      developer.log('HttpException: $e');
      throw Exception('Ошибка HTTP: $e');
    } catch (e) {
      developer.log('Error: $e');
      throw Exception('Ошибка сети: $e');
    }
  }

  // Универсальный POST с обработкой ошибок
  static Future<http.Response> _post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final url = '$baseUrl$path';
    developer.log('POST $url');
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers ?? await _getHeaders(),
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      developer.log('Status: ${response.statusCode}');
      return response;
    } on SocketException catch (e) {
      developer.log('SocketException: $e');
      throw Exception('Нет подключения к серверу. Проверьте интернет.');
    } on HttpException catch (e) {
      developer.log('HttpException: $e');
      throw Exception('Ошибка HTTP: $e');
    } catch (e) {
      developer.log('Error: $e');
      throw Exception('Ошибка сети: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('Ошибка парсинга ответа сервера');
      }
    } else {
      String message = 'Ошибка сервера (${response.statusCode})';
      try {
        final data = jsonDecode(response.body);
        message = data['detail'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }

  // --- АВТОРИЗАЦИЯ ---

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _post(
      '/api/auth/register',
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
    final response = await _post(
      '/api/auth/login',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'SKSQuest/1.0 (Android)',
      },
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
    final response = await _get('/api/auth/me');
    final data = _handleResponse(response);
    return User.fromJson(data);
  }

  // --- ЕЖЕДНЕВНЫЙ ВХОД ---

  static Future<DailyCheckinResult> dailyCheckin() async {
    final response = await _post('/api/daily/checkin');
    final data = _handleResponse(response);
    return DailyCheckinResult.fromJson(data);
  }

  static Future<Map<String, dynamic>> getStreak() async {
    final response = await _get('/api/daily/streak');
    return _handleResponse(response);
  }

  // --- КВЕСТЫ ---

  static Future<List<Quest>> getDailyQuests() async {
    final response = await _get('/api/quests/daily');
    final data = _handleResponse(response);
    return (data as List).map((q) => Quest.fromJson(q)).toList();
  }

  static Future<Map<String, dynamic>> completeQuest(int questId) async {
    final response = await _post(
      '/api/quests/complete',
      body: jsonEncode({'quest_id': questId}),
    );
    return _handleResponse(response);
  }

  // --- КОЛЕСО ФОРТУНЫ ---

  static Future<WheelResult> spinWheel({bool useFree = true}) async {
    final response = await _post('/api/wheel/spin?use_free=$useFree');
    final data = _handleResponse(response);
    return WheelResult.fromJson(data);
  }

  static Future<Map<String, dynamic>> getSpinsInfo() async {
    final response = await _get('/api/wheel/spins-info');
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getWheelProbabilities() async {
    final response = await _get('/api/wheel/probabilities');
    return _handleResponse(response);
  }

  // --- КАТАЛОГ ПРИЗОВ ---

  static Future<List<Prize>> getPrizes({String? category}) async {
    String path = '/api/marketplace/prizes';
    if (category != null) path += '?category=$category';
    final response = await _get(path);
    final data = _handleResponse(response);
    return (data as List).map((p) => Prize.fromJson(p)).toList();
  }

  static Future<Map<String, dynamic>> redeemPrize(int prizeId) async {
    final response = await _post(
      '/api/marketplace/redeem',
      body: jsonEncode({'prize_id': prizeId}),
    );
    return _handleResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getMyRedemptions() async {
    final response = await _get('/api/marketplace/my-redemptions');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  // --- ЛИДЕРБОРД ---

  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await _get('/api/leaderboard');
    final data = _handleResponse(response);
    return (data as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  static Future<List<Achievement>> getAchievements() async {
    final response = await _get('/api/achievements');
    final data = _handleResponse(response);
    return (data as List).map((a) => Achievement.fromJson(a)).toList();
  }

  static Future<Map<String, dynamic>> getMyLeague() async {
    final response = await _get('/api/my-league');
    return _handleResponse(response);
  }

  // --- ОЦЕНЩИК ---

  static Future<GuessPriceSession> startGuessPrice() async {
    final response = await _post('/api/guess-price/start');
    final data = _handleResponse(response);
    return GuessPriceSession.fromJson(data);
  }

  static Future<List<GuessPriceItem>> getGuessPriceItems(int sessionId) async {
    final response = await _get('/api/guess-price/items?session_id=$sessionId');
    final data = _handleResponse(response);
    return (data as List).map((item) => GuessPriceItem.fromJson(item)).toList();
  }

  static Future<GuessPriceResult> submitGuessPrice({
    required int sessionId,
    required int itemId,
    required int guess,
  }) async {
    final response = await _post(
      '/api/guess-price/guess',
      body: jsonEncode({
        'session_id': sessionId,
        'item_id': itemId,
        'guess': guess,
      }),
    );
    final data = _handleResponse(response);
    return GuessPriceResult.fromJson(data);
  }

  static Future<GuessPriceSession> finishGuessPrice(int sessionId) async {
    final response = await _post(
      '/api/guess-price/finish',
      body: jsonEncode({'session_id': sessionId}),
    );
    final data = _handleResponse(response);
    return GuessPriceSession.fromJson(data);
  }
}
