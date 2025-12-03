import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDoctorListPage extends StatefulWidget {
  const AdminDoctorListPage({super.key});

  @override
  State<AdminDoctorListPage> createState() => _AdminDoctorListPageState();
}

class _AdminDoctorListPageState extends State<AdminDoctorListPage> {
  List doctors = [];
  bool loading = true;

  Future<void> fetchDoctors() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("admin_token") ?? "";

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/admin/users"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        setState(() {
          doctors = resBody["doctors"];
          loading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("فشل تحميل الدكاترة")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  Future<void> updateDoctor(String id, {bool? isActive, bool? isApproved}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("admin_token") ?? "";

    final body = {};
    if (isActive != null) body["is_active"] = isActive;
    if (isApproved != null) body["is_approved"] = isApproved;

    final response = await http.put(
      Uri.parse("http://10.0.2.2:8000/admin/doctor/update/$id"),
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      fetchDoctors();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("فشل التحديث")));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("قائمة الدكاترة")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text("${doctor['first_name']} ${doctor['last_name']}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email: ${doctor['email']}"),
                  Text("Active: ${doctor['is_active']}"),
                  Text("Approved: ${doctor['is_approved']}"),
                ],
              ),
              trailing: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: doctor['is_approved']
                        ? null
                        : () => updateDoctor(doctor["_id"], isApproved: true),
                  ),
                  IconButton(
                    icon: Icon(
                      doctor['is_active'] ? Icons.pause : Icons.play_arrow,
                      color: doctor['is_active'] ? Colors.red : Colors.green,
                    ),
                    onPressed: () =>
                        updateDoctor(doctor["_id"], isActive: !doctor['is_active']),
                  ),
                ],
              ),
              onTap: doctor['cv_url'] != null
                  ? () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("CV"),
                    content: Text("رابط السيرة الذاتية: ${doctor['cv_url']}"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("موافق"),
                      )
                    ],
                  ),
                );
              }
                  : null,
            ),
          );
        },
      ),
    );
  }
}
