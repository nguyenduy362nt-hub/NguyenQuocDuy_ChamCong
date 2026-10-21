import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Phiên đăng nhập (lưu JWT trong SharedPreferences).
class Session {
  static const _key = 'qd_chamcong_jwt';
  static String? token;
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Map<String, dynamic> get _claims {
    if (token == null) return {};
    try {
      return JwtDecoder.decode(token!);
    } catch (_) {
      return {};
    }
  }

  static String get role => (_claims['role'] ?? '').toString();
  static String get username => (_claims['unique_name'] ?? '').toString();
  static String get fullName => (_claims['full_name'] ?? username).toString();
  static bool get loggedIn =>
      token != null && token!.isNotEmpty && !JwtDecoder.isExpired(token!);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString(_key);
    if (token != null && JwtDecoder.isExpired(token!)) {
      token = null;
      await p.remove(_key);
    }
  }

  static Future<void> save(String t) async {
    token = t;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, t);
    changes.value++;
  }

  static Future<void> clear() async {
    token = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
    changes.value++;
  }
}

class Api {
  static String get base {
    var b = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5245/api/';
    if (!b.endsWith('/')) b += '/';
    return b;
  }

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
      };

  static Uri _uri(String path, [Map<String, String>? q]) =>
      Uri.parse('$base$path').replace(queryParameters: q);

  static Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      final r = await call().timeout(const Duration(seconds: 20));
      dynamic body;
      if (r.body.isNotEmpty) {
        try {
          body = jsonDecode(utf8.decode(r.bodyBytes));
        } catch (_) {
          body = null;
        }
      }
      if (r.statusCode >= 200 && r.statusCode < 300) return body;
      if (r.statusCode == 401 && Session.token != null) {
        await Session.clear();
        throw ApiException('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại', 401);
      }
      if (r.statusCode == 403) {
        throw ApiException('Bạn không có quyền thực hiện chức năng này', 403);
      }
      String msg = 'Lỗi máy chủ (${r.statusCode})';
      if (body is Map && body['message'] != null) {
        msg = body['message'].toString();
      } else if (body is Map && body['title'] != null) {
        msg = body['title'].toString();
      }
      throw ApiException(msg, r.statusCode);
    } on SocketException {
      throw ApiException('Không kết nối được máy chủ. Hãy kiểm tra API đang chạy (http://localhost:5245) và BASE_URL trong .env');
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu, vui lòng thử lại');
    } on http.ClientException {
      throw ApiException('Không kết nối được máy chủ');
    }
  }

  static Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers()));

  static Future<dynamic> post(String path, [Object? body]) =>
      _send(() => http.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  static Future<dynamic> put(String path, [Object? body]) =>
      _send(() => http.put(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  static Future<dynamic> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers()));

  // ---- Đăng ký / đăng nhập ----
  static Future<void> register(Map<String, dynamic> d) => post('auth/register', d);

  /// Bước 1: trả về {requiresOtp, email, devOtp}
  static Future<Map<String, dynamic>> login(String user, String pass) async {
    final r = await post('auth/login', {'username': user, 'password': pass});
    return Map<String, dynamic>.from(r as Map);
  }

  /// Bước 2: xác thực OTP -> lưu token
  static Future<void> verifyOtp(String user, String code) async {
    final r = await post('auth/verify-otp', {'username': user, 'code': code});
    await Session.save(r['token'] as String);
  }
}
