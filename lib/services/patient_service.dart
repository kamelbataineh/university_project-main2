// هذا الملف مسؤول عن عمليات المريض: الحجز، النتائج، رفع الصور...

import 'api_service.dart';

class PatientService {
  final ApiService _api = ApiService();

  // حجز موعد جديد
  Future<dynamic> bookAppointment(Map data, String token) async {
    return await _api.post("/appointments/create", data, token: token);
  }

  // جلب مواعيد المريض
  Future<dynamic> getAppointments(String token) async {
    return await _api.get("/patients/appointments", token: token);
  }

  // رفع صورة أو تحليل (مثلاً للذكاء الاصطناعي)
  Future<dynamic> uploadResult(Map data, String token) async {
    return await _api.post("/patients/results", data, token: token);
  }

  // جلب النتائج السابقة
  Future<dynamic> getResults(String token) async {
    return await _api.get("/patients/results", token: token);
  }
}

