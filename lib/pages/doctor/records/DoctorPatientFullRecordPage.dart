import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import '../../../core/config/app_font.dart';
import 'EditRecordPage.dart';

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
    if (widget.patientName != null && widget.patientName!.isNotEmpty) {
      patientName = widget.patientName!;
    }
    fetchRecord();
  }

  Future<void> fetchRecord() async {
    setState(() => loading = true); // عرض الـ spinner
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl1/api/v1/doctor/patients/${widget.patientId}/medical_records?page=1&limit=1",
        ),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['records'] is List && data['records'].isNotEmpty) {
          setState(() {
            record = data['records'][0];  // تحديث الـ UI هنا
            patientName = widget.patientName ?? "Unknown";
          });
        } else {
          setState(() => record = null);
        }
      }
    } catch (e) {
      debugPrint("Error fetching record: $e");
      setState(() => record = null);
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= SAFE GET =================
  String safeGet(dynamic map, List<String> path,
      {String defaultValue = "Not provided"}) {
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

      if (current is Map && current.containsKey(r'$date')) {
        final dt = DateTime.parse(current[r'$date']).toLocal();
        return DateFormat("yyyy/MM/dd HH:mm").format(dt);
      }

      if (current is String && current.contains("T")) {
        final dt = DateTime.parse(current).toLocal();
        return DateFormat("yyyy/MM/dd HH:mm").format(dt);
      }

      return current.toString();
    } catch (_) {
      return defaultValue;
    }
  }

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
      return current is List
          ? current.map((e) => e.toString()).toList()
          : [];
    } catch (_) {
      return [];
    }
  }

  // ================= MEDICATIONS =================
  List<String> getMedications(dynamic data) {
    try {
      final meds = data['medications'];
      if (meds is List) {
        return meds.map<String>((m) {
          final name = m['name'] ?? '';
          final dose = m['dose'] ?? '';
          return "$name ($dose)";
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ================= SURGERIES =================
  // ================= SURGERIES =================
  List<String> getSurgeries(dynamic data) {
    try {
      final surgeries = data['surgeries'];
      if (surgeries is List) {
        return surgeries.map<String>((s) {
          final type = s['type'] ?? 'Unknown surgery';

          // التحقق من وجود التاريخ وتحويله
          if (s['date'] != null) {
            if (s['date'] is Map && s['date'][r'$date'] != null) {
              final dt = DateTime.parse(s['date'][r'$date']).toLocal();
              final formatted = DateFormat("yyyy/MM/dd").format(dt);
              return "$type - $formatted";
            } else if (s['date'] is String) {
              final dt = DateTime.parse(s['date']).toLocal();
              final formatted = DateFormat("yyyy/MM/dd").format(dt);
              return "$type - $formatted";
            }
          }

          return type;
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }


  // ================= UI HELPERS =================
  Widget chipList(List<String> items) {
    if (items.isEmpty) {
      return const Text("None", style: TextStyle(fontSize: 16));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items
          .map(
            (e) => Chip(
          label: Text(e),
          backgroundColor: Colors.indigo.shade50,
        ),
      )
          .toList(),
    );
  }

  Widget valueText(String text) =>
      Text(text, style: const TextStyle(fontSize: 16));

  Widget infoCard({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Icon(icon, color: Colors.indigo.shade400),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style:  TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
             SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = record?['data'] ?? {};

    return Scaffold(
      appBar:AppBar(
        backgroundColor: Colors.indigo.shade400,
        centerTitle: true,
        title: SizedBox(
          height: 25,
          child: Marquee(
            text: "Medical Record - $patientName",
            style: const TextStyle(
              fontSize: 16, // 🟢 تصغير حجم الخط
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            scrollAxis: Axis.horizontal,
            blankSpace: 20,
            velocity: 30, // 🟢 سرعة الحركة
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 10,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(seconds: 1),
            decelerationCurve: Curves.easeOut,
          ),
        ),
      ),
      body: loading
          ?  Center(child: CircularProgressIndicator())
          : record == null
          ?  Center(child: Text("No medical record found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoCard(
              icon: Icons.person,
              title: "Basic Information",
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  valueText(
                      "Age: ${safeGet(data, ['basic_info', 'age'])}"),
                  const SizedBox(height: 6),
                  valueText(
                      "Gender: ${safeGet(data, ['basic_info', 'gender'])}"),
                ],
              ),
            ),
            infoCard(
                icon: Icons.favorite,
                title: "Diseases",
                content:
                chipList(safeGetList(data, ['diseases']))),
            infoCard(
                icon: Icons.warning,
                title: "Allergies",
                content:
                chipList(safeGetList(data, ['allergies']))),
            infoCard(
                icon: Icons.medication,
                title: "Medications",
                content: chipList(getMedications(data))),
            infoCard(
                icon: Icons.local_hospital,
                title: "Surgeries",
                content: chipList(getSurgeries(data))),
            infoCard(
                icon: Icons.family_restroom,
                title: "Family History",
                content: chipList(
                    safeGetList(data, ['family_history']))),
            infoCard(
              icon: Icons.analytics,
              title: "Diagnosis",
              content: valueText(data['diagnosis']?.toString() ?? 'Not provided'),
            ),

            infoCard(
              icon: Icons.schedule,
              title: "Record Timeline",
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  valueText(
                      "Created at: ${safeGet(record, ['created_at'])}"),
                  const SizedBox(height: 6),
                  valueText(
                      "Last updated: ${safeGet(record, ['updated_at'])}"),
                ],
              ),
            ),
            SizedBox(height: 20,),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
              label: Text(
                "Modification of the medical record",
                style: AppFont.regular(
                  size: 13,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                shadowColor: Colors.white,
                minimumSize: const Size(120, 38), // نفس حجم الأزرار الصغيرة
              ),
              onPressed: () {
                final rawId = record!['_id'];
                final recordId = rawId is Map ? rawId['\$oid'] : rawId.toString();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditRecordPage(
                      token: widget.token,
                      patientId: widget.patientId,
                      recordId: recordId,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 50,)
          ],
        ),
      ),
    );
  }
}
