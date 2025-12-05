// admin_patient_profile_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPatientProfilePage extends StatefulWidget {
  final Map patient;
  const AdminPatientProfilePage({super.key, required this.patient});

  @override
  State<AdminPatientProfilePage> createState() =>
      _AdminPatientProfilePageState();
}

class _AdminPatientProfilePageState extends State<AdminPatientProfilePage> {
  bool loading = false;
  late bool isActive;

  final String baseUrl = "http://10.0.2.2:8000"; // API

  @override
  void initState() {
    super.initState();
    isActive = widget.patient["is_active"] ?? true;
  }

  // ------------------ تفعيل/إيقاف الحساب ------------------
  Future<void> toggleActive() async {
    setState(() => loading = true);
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/patient/${widget.patient["_id"]}/toggle_active"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"is_active": !isActive}),
      );

      if (response.statusCode == 200) {
        setState(() {
          isActive = !isActive;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم تعديل حالة الحساب بنجاح ✅")),
        );
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
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: Text("${patient["first_name"]} ${patient["last_name"]}"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // اسم المريض
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text("${patient["first_name"]} ${patient["last_name"]}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text("Patient Name"),
              ),
            ),

            const SizedBox(height: 10),

            // البريد الإلكتروني
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: Text(patient["email"] ?? ""),
                subtitle: const Text("البريد الإلكتروني"),
              ),
            ),

            const SizedBox(height: 10),

            // زر تفعيل/إلغاء التفعيل مع أيقونة
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(isActive ? "نشط" : "غير نشط"),
                trailing: IconButton(
                  icon: Icon(
                    isActive ? Icons.pause : Icons.play_arrow,
                    color: isActive ? Colors.red : Colors.green,
                  ),
                  onPressed: toggleActive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
