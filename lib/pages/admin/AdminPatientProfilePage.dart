// admin_patient_profile_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPatientProfilePage extends StatefulWidget {
  final Map patient;
  final String adminToken;
  const AdminPatientProfilePage({super.key, required this.patient, required this.adminToken});

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
        headers: {
          "Authorization": "Bearer ${widget.adminToken}",
          "Content-Type": "application/json",
        },
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
                subtitle: const Text("Email"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(isActive ? "Active" : "inactive"),
                trailing: IconButton(
                  icon: Icon(
                    isActive ? Icons.pause : Icons.play_arrow,
                    color: isActive ? Colors.red : Colors.green,
                  ),
                  onPressed: toggleActive,
                ),
              ),
            ),


            // أسفل كرت تفعيل/إيقاف الحساب
            const SizedBox(height: 10),

// كرت حذف الحساب
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Delete account",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  // نافذة التأكيد
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm deletion"),
                      content: const Text("Are you sure you want to delete this patient's account?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("no"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("yes"),
                        ),
                      ],
                    ),
                  );

                  if (confirm != null && confirm) {
                    setState(() => loading = true);
                    try {
                      final response = await http.delete(
                        Uri.parse("http://10.0.2.2:8000/admin/patient/${widget.patient["_id"]}"),
                        headers: {
                          "Authorization": "Bearer ${widget.adminToken}",
                          "Content-Type": "application/json",
                        },
                      );


                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم حذف الحساب بنجاح ✅")),
                        );
                        Navigator.pop(context); // العودة للصفحة السابقة بعد الحذف
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("فشل حذف الحساب")),
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
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
