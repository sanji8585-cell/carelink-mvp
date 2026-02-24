import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  
  static const String baseUrl = 'http://localhost:3000/api'; // 개발 환경

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired - redirect to login
          _storage.delete(key: 'auth_token');
        }
        handler.next(error);
      },
    ));
  }

  // ===== Auth =====
  Future<Map<String, dynamic>> signup(String email, String password, String name, {String? phone}) async {
    final res = await _dio.post('/auth/signup', data: {
      'email': email, 'password': password, 'name': name, 'phone': phone,
    });
    await _storage.write(key: 'auth_token', value: res.data['token']);
    return res.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    await _storage.write(key: 'auth_token', value: res.data['token']);
    return res.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data;
  }

  Future<void> updateFcmToken(String token) async {
    await _dio.put('/auth/fcm-token', data: {'fcmToken': token});
  }

  // ===== Senior =====
  Future<Map<String, dynamic>> registerSenior(Map<String, dynamic> data) async {
    final res = await _dio.post('/seniors', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> linkSenior(String inviteCode) async {
    final res = await _dio.post('/seniors/link', data: {'inviteCode': inviteCode});
    return res.data;
  }

  Future<List<dynamic>> getMySeniors() async {
    final res = await _dio.get('/seniors');
    return res.data;
  }

  // ===== Conversation (부모님 앱) =====
  Future<Map<String, dynamic>> startConversation(String seniorId) async {
    final res = await _dio.post('/conversations/start', data: {'seniorId': seniorId});
    return res.data;
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String content) async {
    final res = await _dio.post('/conversations/$conversationId/message', data: {'content': content});
    return res.data;
  }

  Future<Map<String, dynamic>> endConversation(String conversationId) async {
    final res = await _dio.post('/conversations/$conversationId/end');
    return res.data;
  }

  // ===== Health =====
  Future<void> submitDeviceData(Map<String, dynamic> data) async {
    await _dio.post('/health/device-data', data: data);
  }

  Future<Map<String, dynamic>> getTodayHealth(String seniorId) async {
    final res = await _dio.get('/health/$seniorId/today');
    return res.data;
  }

  Future<Map<String, dynamic>> getWeeklyHealth(String seniorId) async {
    final res = await _dio.get('/health/$seniorId/weekly');
    return res.data;
  }

  // ===== Dashboard =====
  Future<Map<String, dynamic>> getDashboard(String seniorId) async {
    final res = await _dio.get('/dashboard/$seniorId');
    return res.data;
  }

  // ===== Medication =====
  Future<List<dynamic>> getTodayMedications(String seniorId) async {
    final res = await _dio.get('/medications/$seniorId/today');
    return res.data;
  }

  Future<void> logMedication(String alertId, String status) async {
    await _dio.post('/medications/log', data: {'alertId': alertId, 'status': status});
  }

  // ===== SOS =====
  Future<void> triggerSos(String seniorId, {String type = 'MANUAL', double? lat, double? lng}) async {
    await _dio.post('/sos/trigger', data: {
      'seniorId': seniorId, 'type': type, 'latitude': lat, 'longitude': lng,
    });
  }

  // ===== Reports =====
  Future<Map<String, dynamic>> getLatestReport(String seniorId) async {
    final res = await _dio.get('/reports/$seniorId/latest');
    return res.data;
  }

  // ===== Notifications =====
  Future<Map<String, dynamic>> getNotifications({int page = 1, bool unreadOnly = false}) async {
    final res = await _dio.get('/notifications', queryParameters: {
      'page': page, 'unreadOnly': unreadOnly,
    });
    return res.data;
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.put('/notifications/$id/read');
  }

  // ===== Conversations (자녀 조회) =====
  Future<List<dynamic>> getSeniorConversations(String seniorId, {int page = 1}) async {
    final res = await _dio.get('/conversations/senior/$seniorId', queryParameters: {'page': page});
    return res.data;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }
}
