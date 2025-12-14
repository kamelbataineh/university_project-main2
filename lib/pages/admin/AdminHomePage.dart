import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:university_project/pages/admin/AdminPatientListPage.dart';
import 'package:university_project/pages/auth/LandingPage.dart';
import 'AdminDoctorListPage.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("admin_token") ?? "";

    try {
      // إرسال طلب تسجيل خروج للسيرفر (اختياري)
      await http.post(
        Uri.parse("http://10.0.2.2:8000/admin/logout"),
        headers: {"Authorization": "Bearer $token"},
      );
    } catch (e) {
      // لو فشل الاتصال، نكمل تسجيل الخروج محلياً
      print("Logout API failed: $e");
    }

    // حذف التوكن محلياً
    await prefs.remove("admin_token");

    // العودة لصفحة تسجيل الدخول
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              bool? confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Do you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Yes"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await logout(context);
              }
            },
          ),

        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.medical_services),
              label: const Text("Doctors"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDoctorListPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text("Patients"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPatientListPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
