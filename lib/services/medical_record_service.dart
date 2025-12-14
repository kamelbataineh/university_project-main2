import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicalRecordService {
  final String baseUrl;
  final String token;

  MedicalRecordService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  /// Get all medical records for a patient
  Future<List<dynamic>> getRecords(String patientId) async {
    final url = Uri.parse("$baseUrl/api/v1/doctor/patients/$patientId/medical_records");

    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to fetch records");
  }

  Future<bool> createFullMedicalRecord({
    required String patientId,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse("$baseUrl/api/v1/medical_records");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "patient_id": patientId,
        "data": data,
      }),
    );

    print("📤 Sending: ${jsonEncode({
      "patient_id": patientId,
      "data": data,
    })}");

    print("📥 Response: ${response.body}");

    return response.statusCode == 201;
  }

  Future<bool> updateRecord({required String recordId, required Map<String, dynamic> data}) async {
    final response = await http.put(
      Uri.parse("$baseUrl/medical_records/$recordId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true; // ✅ تم التحديث بنجاح
    } else {
      print("خطأ تحديث السجل: ${response.body}");
      return false; // ❌ فشل التحديث
    }
  }
  Future<Map<String, dynamic>> getRecord(String recordId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/v1/medical_records/$recordId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("فشل جلب السجل: ${response.statusCode}");
    }
  }


  /// Delete record
  Future<bool> deleteRecord(String patientId, String recordId) async {
    final url = Uri.parse("$baseUrl/api/v1/doctor/patients/$patientId/medical_records/$recordId");

    final response = await http.delete(url, headers: _headers);

    return response.statusCode == 200;
  }
}
