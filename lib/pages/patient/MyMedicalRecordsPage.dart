import 'package:flutter/material.dart';
import '../../services/MedicalRecordService.dart';

class MyMedicalRecordsPage extends StatefulWidget {
  final String token;
  final String userId;

  const MyMedicalRecordsPage({super.key, required this.token, required this.userId});

  @override
  State<MyMedicalRecordsPage> createState() => _MyMedicalRecordsPageState();
}
//
class _MyMedicalRecordsPageState extends State<MyMedicalRecordsPage> {
  List records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    try {
      final data = await MedicalRecordService(
          baseUrl: "http://10.0.2.2:8000", token: widget.token)
          .getMyMedicalRecords(page: 1, limit: 20);
      setState(() {
        records = data['records'];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Medical Records")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
          ? const Center(child: Text("No medical records found."))
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          final data = record["data"] ?? {};
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 3,
            child: ListTile(
              title: Text(data["diagnosis"] ?? "No diagnosis",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Updated at: ${record["updated_at"] ?? ""}"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MedicalRecordDetailPage(
                          record: record,
                        )));
              },
            ),
          );
        },
      ),
    );
  }
}

class MedicalRecordDetailPage extends StatelessWidget {
  final Map record;
  const MedicalRecordDetailPage({super.key, required this.record});

  Widget section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        child,
      ]),
    );
  }
////////////////////
  @override
  Widget build(BuildContext context) {
    final data = record["data"] ?? {};

    // Basic Info
    final basicInfo = data["basic_info"] ?? {};
    final age = basicInfo["age"]?.toString() ?? "-";
    final gender = basicInfo["gender"]?.toString() ?? "-";

    // Lists
    final diseases = (data["diseases"] as List? ?? []).map((e) => e.toString()).toList();
    final allergies = (data["allergies"] as List? ?? []).map((e) => e.toString()).toList();
    final medications = (data["medications"] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    final surgeries = (data["surgeries"] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    final familyHistory = (data["family_history"] as List? ?? []).map((e) => e.toString()).toList();

    // Lifestyle & others
    final lifestyle = data["lifestyle"] ?? {};
    final exercise = lifestyle["exercise"]?.toString() ?? "-";
    final stress = lifestyle["stress_level"]?.toString() ?? "-";
    final symptoms = data["current_symptoms"]?.toString() ?? "-";
    final notes = data["notes"]?.toString() ?? "-";
    final diagnosis = data["diagnosis"]?.toString() ?? "-";

    final doctorId = (record["doctor_id"] is Map && record["doctor_id"]?["\$oid"] != null)
        ? record["doctor_id"]["\$oid"].toString()
        : "Unknown Doctor";

    return Scaffold(
      appBar: AppBar(title: const Text("Record Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          section("Doctor:", Text(doctorId, style: const TextStyle(fontSize: 16))),
          section("Diagnosis:", Text(diagnosis, style: const TextStyle(fontSize: 16))),
          section("Doctor's Notes:", Text(notes, style: const TextStyle(fontSize: 16))),
          section("Basic Info:", Text("Age: $age, Gender: $gender")),
          section("Diseases:", Column(children: diseases.map((e) => Text(e.isEmpty ? "-" : e)).toList())),
          section("Allergies:", Column(children: allergies.map((e) => Text(e.isEmpty ? "-" : e)).toList())),
          section(
              "Medications:",
              Column(
                  children: medications
                      .map((m) => Text("${m['name'] ?? '-'} - ${m['dose'] ?? '-'}"))
                      .toList())),
          section(
            "Surgeries:",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: surgeries.map<Widget>((s) {
                String dateStr = '-';
                final date = s['date'];
                if (date != null) {
                  if (date is Map && date.containsKey('\$date')) {
                    dateStr = date['\$date']?.toString().substring(0, 10) ?? '-';
                  } else if (date is String) {
                    dateStr = date.substring(0, 10);
                  }
                }
                return Text("${s['type'] ?? '-'} - $dateStr");
              }).toList(),
            ),
          ),
          section("Family History:", Column(children: familyHistory.map((e) => Text(e.isEmpty ? "-" : e)).toList())),
          section("Lifestyle:", Text("Exercise: $exercise, Stress Level: $stress")),
          section("Current Symptoms:", Text(symptoms)),
          section("Last Updated:", Text(record["updated_at"]?.toString() ?? "-")),
        ]),
      ),
    );
  }
}
