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
  Future<bool> updateRecord({
    required String recordId,
    required String patientId,
    required Map<String, dynamic> data,
    String changesDescription = "Updated record fields", // ⬅️ حقل الوصف المطلوب
  }) async {
    final url = Uri.parse("$baseUrl/api/v1/medical_records/$recordId");

    // بناء الـ payload النهائي
    final payload = {
      "patient_id": patientId,
      "data": data,
      "changes_description": changesDescription, // ⬅️ أضف هذا
    };

    print("📤 Sending update: ${jsonEncode(payload)}");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(payload),
    );

    print("📥 Response: ${response.body}");

    return response.statusCode == 200;
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
