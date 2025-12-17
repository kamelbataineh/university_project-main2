import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';
import 'DoctorPatientFullRecordPage.dart';

class DoctorRecordsPage extends StatefulWidget {
  final String token;

  const DoctorRecordsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<DoctorRecordsPage> createState() => _DoctorRecordsPageState();
}

class _DoctorRecordsPageState extends State<DoctorRecordsPage> {
  List<dynamic> records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  // ================== جلب بيانات المريض ==================
  Future<Map<String, dynamic>> fetchPatient(String patientId) async {
    final url = Uri.parse("$baseUrl1/api/v1/patients/$patientId");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  // ================== تنسيق التاريخ ==================
  String formatDate(dynamic dateField) {
    try {
      if (dateField == null) return '';

      // الحالة 1: MongoDB Map {$date}
      if (dateField is Map && dateField.containsKey('\$date')) {
        final dateTime = DateTime.parse(dateField['\$date']);
        return "${dateTime.year}/${dateTime.month}/${dateTime.day}";
      }

      // الحالة 2: String ISO
      if (dateField is String) {
        final dateTime = DateTime.parse(dateField);
        return "${dateTime.year}/${dateTime.month}/${dateTime.day}";
      }

      return '';
    } catch (e) {
      return '';
    }
  }


  // ================== جلب سجلات الدكتور ==================
  Future<void> _fetchRecords() async {
    final url = Uri.parse(
        "$baseUrl1/api/v1/doctor/my_created_records?page=1&limit=100");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}",
      },
    );

    if (response.statusCode != 200) {
      setState(() {
        loading = false;
        records = [];
      });
      return;
    }

    final data = jsonDecode(response.body);
    final fetchedRecords = data['records'] ?? [];

    // جلب أسماء المرضى بشكل آمن
    final updatedRecords = await Future.wait(
      fetchedRecords.map<Future<dynamic>>((record) async {
        String patientId = '';

        final patientIdRaw = record['patient_id'];
        if (patientIdRaw is Map && patientIdRaw.containsKey('\$oid')) {
          patientId = patientIdRaw['\$oid'];
        } else if (patientIdRaw is String) {
          patientId = patientIdRaw;
        }

        final patientData = await fetchPatient(patientId);
        record['patient_name'] =
        "${patientData['first_name'] ?? ''} ${patientData['last_name'] ?? ''}";

        return record;
      }).toList(),
    );

    setState(() {
      records = updatedRecords;
      loading = false;
    });
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Records"),
        backgroundColor: Colors.indigo,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
          ? const Center(child: Text("No records found"))
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.folder_shared),
              title: Text(
                "Patient: ${record['patient_name'] ?? 'Unknown'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Created at: ${formatDate(record['created_at'])}",
              ),
              trailing:
              const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                String patientId = '';

                final patientIdRaw = record['patient_id'];
                if (patientIdRaw is Map && patientIdRaw.containsKey('\$oid')) {
                  patientId = patientIdRaw['\$oid'];
                } else if (patientIdRaw is String) {
                  patientId = patientIdRaw;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorPatientFullRecordPage(
                      token: widget.token,
                      patientId: patientId,
                      patientName: record['patient_name'],
                    ),
                  ),
                );

              },

            ),
          );
        },
      ),
    );
  }
}
