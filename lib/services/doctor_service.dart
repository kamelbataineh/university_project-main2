// هذا الملف مسؤول عن عمليات الطبيب: المواعيد، المرضى، تعديل المعلومات...

import 'api_service.dart';

class DoctorService {
  final ApiService _api = ApiService();

  // جلب مواعيد الطبيب
  Future<dynamic> getAppointments(String token) async {
    return await _api.get("/doctors/appointments", token: token);
  }

  // جلب قائمة المرضى
  Future<dynamic> getPatients(String token) async {
    return await _api.get("/doctors/patients", token: token);
  }

  // تعديل بيانات الطبيب
  Future<dynamic> updateProfile(Map data, String token) async {
    return await _api.put("/doctors/update", data, token: token);
  }

  // حذف موعد
  Future<dynamic> deleteAppointment(int id, String token) async {
    return await _api.delete("/appointments/$id", token: token);
  }
}
