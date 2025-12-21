import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
              title: Text(
                data["diagnosis"] ?? "No diagnosis",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  "Updated at: ${record["updated_at"] != null ?
                  DateFormat('yyyy/MM/dd').format(DateTime.parse(record["updated_at"]))
                      : ""}"
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicalRecordDetailPage(
                      record: record,
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


class MedicalRecordDetailPage extends StatelessWidget {
  final Map record;
  const MedicalRecordDetailPage({super.key, required this.record});

  // ================= Helper Widgets =================
  Widget infoCard({required IconData icon, required String title, required Widget content}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: Colors.purple.shade100, child: Icon(icon, color: Colors.purple)),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          content,
        ]),
      ),
    );
  }

  Widget valueText(String text) => Text(text, style: const TextStyle(fontSize: 16));

  Widget chipList(List<String> items) {
    if (items.isEmpty) return const Text("None", style: TextStyle(fontSize: 16));
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items.map((e) => Chip(label: Text(e), backgroundColor: Colors.purple.shade50)).toList(),
    );
  }

  List<String> getMedications(dynamic data) {
    try {
      final meds = data['medications'];
      if (meds is List) {
        return meds.map<String>((m) => "${m['name'] ?? '-'} (${m['dose'] ?? '-'})").toList();
      }
    } catch (_) {}
    return [];
  }

  List<String> getSurgeries(dynamic data) {
    try {
      final surgeries = data['surgeries'];
      if (surgeries is List) {
        return surgeries.map<String>((s) {
          final type = s['type'] ?? 'Unknown';
          String dateStr = '-';
          final date = s['date'];
          if (date != null) {
            if (date is Map && date.containsKey(r'$date')) {
              dateStr = DateFormat("yyyy/MM/dd").format(DateTime.parse(date[r'$date']).toLocal());
            } else if (date is String) {
              dateStr = DateFormat("yyyy/MM/dd").format(DateTime.parse(date).toLocal());
            }
          }
          return "$type - $dateStr";
        }).toList();
      }
    } catch (_) {}
    return [];
  }
  String formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      DateTime dt;

      // لو التاريخ Map و فيه $date
      if (date is Map && date.containsKey(r'$date')) {
        dt = DateTime.parse(date[r'$date']).toLocal();
      }
      // لو التاريخ String
      else if (date is String) {
        dt = DateTime.parse(date).toLocal();
      } else {
        return '-';
      }

      return DateFormat("yyyy/MM/dd").format(dt);
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = record["data"] ?? {};
    final basicInfo = data["basic_info"] ?? {};
    final age = basicInfo["age"]?.toString() ?? "-";
    final gender = basicInfo["gender"]?.toString() ?? "-";

    final diseases = (data["diseases"] as List? ?? []).map((e) => e.toString()).toList();
    final allergies = (data["allergies"] as List? ?? []).map((e) => e.toString()).toList();
    final medications = getMedications(data);
    final surgeries = getSurgeries(data);
    final familyHistory = (data["family_history"] as List? ?? []).map((e) => e.toString()).toList();

    final lifestyle = data["lifestyle"] ?? {};
    final exercise = lifestyle["exercise"]?.toString() ?? "-";
    final stress = lifestyle["stress_level"]?.toString() ?? "-";

    final symptoms = data["current_symptoms"]?.toString() ?? "-";
    final notes = data["notes"]?.toString() ?? "-";
    final diagnosis = data["diagnosis"]?.toString() ?? "-";



    return Scaffold(
      appBar: AppBar(title: const Text("Medical Record Details"), backgroundColor: Colors.purple),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          infoCard(
            icon: Icons.person,
            title: "Doctor",
            content: valueText(record["doctor_name"] ?? "Unknown Doctor"),
          ),
          infoCard(icon: Icons.analytics, title: "Diagnosis", content: valueText(diagnosis)),
          infoCard(icon: Icons.note, title: "Doctor's Notes", content: valueText(notes)),
          infoCard(
            icon: Icons.person_outline,
            title: "Basic Info",
            content: valueText("Age       :     $age \nGender :     $gender"),
          ),
          infoCard(icon: Icons.favorite, title: "Diseases", content: chipList(diseases)),
          infoCard(icon: Icons.warning, title: "Allergies", content: chipList(allergies)),
          infoCard(icon: Icons.medication, title: "Medications", content: chipList(medications)),
          infoCard(icon: Icons.local_hospital, title: "Surgeries", content: chipList(surgeries)),
          infoCard(icon: Icons.family_restroom, title: "Family History", content: chipList(familyHistory)),
          infoCard(icon: Icons.fitness_center, title: "Lifestyle", content: valueText("Exercise: $exercise   ------>    Stress: $stress")),
          infoCard(icon: Icons.sick, title: "Current Symptoms", content: valueText(symptoms)),
          infoCard(
            icon: Icons.schedule,
            title: "Record Timeline",
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                valueText("Created at      :      ${formatDate(record['created_at']?.toString())}"),
                valueText("Last updated :      ${formatDate(record['updated_at']?.toString())}"),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
