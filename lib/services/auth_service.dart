// هذا الملف مسؤول عن تسجيل الدخول والتسجيل
// يستخدم ApiService للتعامل مع السيرفر

import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // تسجيل الدخول
  Future<dynamic> login(String username, String password, String role) async {
    final data = {
      "username": username,
      "password": password,
    };

    final endpoint = role == "doctor"
        ? "/doctors/login"
        : "/patients/login";

    return await _api.post(endpoint, data);
  }

  // تسجيل طبيب جديد
  Future<dynamic> registerDoctor(Map doctorData) async {
    return await _api.post("/doctors/register", doctorData);
  }

  // تسجيل مريض جديد
  Future<dynamic> registerPatient(Map patientData) async {
    return await _api.post("/patients/register", patientData);
  }
}
