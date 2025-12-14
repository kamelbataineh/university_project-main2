import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'package:intl/intl.dart';

class DoctorPatientFullRecordPage extends StatefulWidget {
  final String patientId;
  final String token;
  final String? patientName;

  const DoctorPatientFullRecordPage({
    Key? key,
    required this.patientId,
    required this.token,
    this.patientName,
  }) : super(key: key);

  @override
  State<DoctorPatientFullRecordPage> createState() =>
      _DoctorPatientFullRecordPageState();
}

class _DoctorPatientFullRecordPageState
    extends State<DoctorPatientFullRecordPage> {
  Map<String, dynamic>? record;
  bool loading = true;
  String patientName = "Unknown";

  @override
  void initState() {
    super.initState();
    // استخدم الاسم المار من الصفحة السابقة إذا موجود
    if (widget.patientName != null && widget.patientName!.isNotEmpty) {
      patientName = widget.patientName!;
    }
    fetchRecord();
  }

  Future<void> fetchRecord() async {
    try {
      final response = await http.get(
        Uri.parse(
            "$baseUrl1/api/v1/doctor/patients/${widget.patientId}/medical_records?page=1&limit=1"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['records'] != null && data['records'].isNotEmpty) {
          record = data['records'][0];

          // إذا الاسم غير موجود، خذه من السجل نفسه
          patientName = patientName.isNotEmpty
              ? patientName
              : (data['patient_name'] ??
              safeGet(record, ['patient_name'], defaultValue: "Unknown"));
        }
      } else {
        print("❌ Failed to load record: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching record: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  String safeGet(dynamic map, List<String> path, {String defaultValue = "Not provided"}) {
    try {
      dynamic current = map;
      for (var key in path) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return defaultValue;
        }
      }
      if (current == null) return defaultValue;

      // إذا كان Map ويحتوي على '$date' → حوّله للصيغة YYYY/MM/DD HH:mm
      if (current is Map && current.containsKey(r'$date')) {
        DateTime dt = DateTime.parse(current[r'$date'].toString()).toLocal();
        return DateFormat("yyyy/MM/dd HH:mm").format(dt);
      }

      // إذا كان نص ISO مباشر (مع T)
      if (current is String && current.contains("T")) {
        DateTime dt = DateTime.parse(current).toLocal();
        return DateFormat("yyyy/MM/dd HH:mm").format(dt);
      }

      return current.toString();
    } catch (e) {
      return defaultValue;
    }
  }

  // للوصول الآمن للقوائم
  List<String> safeGetList(dynamic map, List<String> path) {
    try {
      dynamic current = map;
      for (var key in path) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return [];
        }
      }
      if (current is List) {
        return current.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Widget buildSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget buildListSection(String title, List<String> list) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          list.isNotEmpty
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list
                .map((e) =>
                Text("- $e", style: const TextStyle(fontSize: 16)))
                .toList(),
          )
              : const Text('None', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = record?['data'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text("السجل الطبي - $patientName"),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : record == null
          ? const Center(child: Text("لا يوجد سجل طبي لهذا المريض"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSection("العمر", safeGet(data, ['basic_info', 'age'])),
            buildSection("الجنس", safeGet(data, ['basic_info', 'gender'])),
            buildListSection("الأمراض", safeGetList(data, ['diseases'])),
            buildListSection("الحساسية", safeGetList(data, ['allergies'])),
            buildListSection("الأدوية", safeGetList(data, ['medications'])),
            buildListSection("العمليات", safeGetList(data, ['surgeries'])),
            buildListSection("التاريخ العائلي", safeGetList(data, ['family_history'])),
            buildSection("أسلوب الحياة - ممارسة الرياضة",
                safeGet(data, ['lifestyle', 'exercise'])),
            buildSection("أسلوب الحياة - مستوى التوتر",
                safeGet(data, ['lifestyle', 'stress_level'])),
            buildSection("الأعراض الحالية", safeGet(data, ['current_symptoms'])),
            buildSection("الملاحظات", safeGet(data, ['notes'])),
            buildSection("التشخيص", safeGet(data, ['diagnosis'])),
            buildSection("تاريخ الإنشاء", safeGet(record, ['created_at'])),
            buildSection("آخر تحديث", safeGet(record, ['updated_at'])),

          ],
        ),
      ),
    );
  }
}
