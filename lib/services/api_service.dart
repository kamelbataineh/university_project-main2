// هذا الملف هو الأساس لكل الاتصالات مع السيرفر (API)
// الهدف: توحيد طريقة إرسال واستقبال البيانات من السيرفر

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart'; // لاستعمال baseUrl

class ApiService {
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // دالة GET
  Future<dynamic> get(String endpoint, {String? token}) async {
    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: _withAuth(token),
    );
    return _handleResponse(response);
  }

  // دالة POST
  Future<dynamic> post(String endpoint, Map data, {String? token}) async {
    final response = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: _withAuth(token),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // دالة PUT (تعديل)
  Future<dynamic> put(String endpoint, Map data, {String? token}) async {
    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: _withAuth(token),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // دالة DELETE
  Future<dynamic> delete(String endpoint, {String? token}) async {
    final response = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: _withAuth(token),
    );
    return _handleResponse(response);
  }

  // ----------------------------------------

  // إضافة التوكن للهيدر إذا موجود
  Map<String, String> _withAuth(String? token) {
    if (token != null) {
      return {...headers, 'Authorization': 'Bearer $token'};
    }
    return headers;
  }

  // معالجة الاستجابة من السيرفر
  dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception("خطأ من السيرفر: ${data['detail'] ?? response.body}");
    }
  }
}
