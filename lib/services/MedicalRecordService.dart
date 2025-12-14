import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicalRecordService {
  final String baseUrl;
  final String token;

  MedicalRecordService({required this.baseUrl, required this.token});

  // ===================== جلب سجلات المريض =====================
  Future<Map<String, dynamic>> getMyMedicalRecords({int page = 1, int limit = 10}) async {
    final url = Uri.parse('$baseUrl/api/v1/my_medical_records?page=$page&limit=$limit');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load medical records');
    }
  }

// ===================== دوال إضافية لو حبيت =====================
// مثل createRecord, getRecordById, searchRecords ... إلخ
}
