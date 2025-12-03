// admin_patient_list_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPatientListPage extends StatefulWidget {
  const AdminPatientListPage({super.key});

  @override
  State<AdminPatientListPage> createState() => _AdminPatientListPageState();
}

class _AdminPatientListPageState extends State<AdminPatientListPage> {
  List patients = [];
  bool loading = false;
  final String baseUrl = "http://10.0.2.2:8000"; // غيّر حسب API

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  // ------------------ جلب جميع المرضى ------------------
  Future<void> fetchPatients() async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/patients"));
      if (response.statusCode == 200) {
        setState(() {
          patients = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل جلب المرضى")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // ------------------ تفعيل/إيقاف الحساب ------------------
  Future<void> toggleActive(String patientId, bool currentStatus) async {
    setState(() => loading = true);
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/patient/$patientId/toggle_active"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"is_active": !currentStatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم تعديل حالة الحساب بنجاح ✅")),
        );
        fetchPatients(); // تحديث القائمة
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل تعديل حالة الحساب")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("قائمة المرضى"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : patients.isEmpty
          ? const Center(child: Text("لا يوجد مرضى"))
          : ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: patient["profile_image_url"] != null
                    ? NetworkImage("http://10.0.2.2:8000/${patient["profile_image_url"]}")
                    : null,
                child: patient["profile_image_url"] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text("${patient["first_name"]} ${patient["last_name"]}"),
              subtitle: Text(patient["email"] ?? ""),
              trailing: Switch(
                value: patient["is_active"] ?? true,
                onChanged: (val) {
                  toggleActive(patient["_id"], patient["is_active"]);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
