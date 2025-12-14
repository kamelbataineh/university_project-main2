import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PdfViewerPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class DoctorProfilePage extends StatefulWidget {
  final Map doctor;
  final Function()? onApprove;
  final Function()? onToggleActive;

  const DoctorProfilePage({
    super.key,
    required this.doctor,
    this.onApprove,
    this.onToggleActive,
  });

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  late Map doctor;
  List doctors = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    doctor = Map.from(widget.doctor); // نعمل نسخة محلية لتحديث الواجهة
  }

  // جلب الدكاترة من السيرفر
  Future<void> fetchDoctors() async {
    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("admin_token") ?? "";

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/admin/doctor"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        setState(() {
          doctors = resBody["doctors"];
          loading = false;
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("فشل تحميل الدكاترة")));
        setState(() => loading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
      setState(() => loading = false);
    }
  }

  // تحديث حالة الطبيب
  Future<void> updateDoctor(String id,
      {bool? isActive, bool? isApproved}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("admin_token") ?? "";

    final body = {};
    if (isActive != null) body["is_active"] = isActive;
    if (isApproved != null) body["is_approved"] = isApproved;

    final response = await http.put(
      Uri.parse("http://10.0.2.2:8000/admin/doctor/update/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      fetchDoctors();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("فشل التحديث")));
    }
  }
  Future<void> deleteDoctor(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("admin_token") ?? "";

    final response = await http.delete(
      Uri.parse("http://10.0.2.2:8000/admin/doctor/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حذف الدكتور بنجاح ✅")),
      );
      fetchDoctors(); // إعادة تحميل القائمة
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل حذف الدكتور ❌")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cvUrl = doctor['cv_url'];

    return Scaffold(
      appBar:
          AppBar(title: Text("${doctor['first_name']} ${doctor['last_name']}")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Email
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text("Email"),
                  subtitle: Text("${doctor['email']}"),
                ),
              ),

              // Phone
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text("Phone"),
                  subtitle: Text("${doctor['phone_number'] ?? '-'}"),
                ),
              ),

              // Approved
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text("Approved"),
                  subtitle: Text("${doctor['is_approved']}"),
                  trailing: doctor['is_approved'] == true
                      ? null // إذا تمت الموافقة، لا يظهر الزر
                      : ElevatedButton(
                    onPressed: () {
                      // عرض نافذة التأكيد
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("تأكيد"),
                          content: const Text("هل تريد الموافقة على هذا الحساب؟"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("لا"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // إغلاق الـ Dialog

                                // تحديث الحالة محليًا
                                setState(() {
                                  doctor['is_approved'] = true;
                                });

                                // إرسال التحديث للسيرفر
                                updateDoctor(doctor["_id"], isApproved: true);

                                // عرض SnackBar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("تمت الموافقة على الحساب"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text("نعم"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("موافق"),
                  ),
                ),
              ),


              // Active مع أيقونة + زر مباشر
              // Active مع أيقونة + زر مباشر
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("الحساب"),
                  subtitle: Text(doctor['is_active'] ? "Active" : "Not Active"),
                  trailing: IconButton(
                    icon: Icon(
                      doctor['is_active'] ? Icons.pause : Icons.play_arrow,
                      color: doctor['is_active'] ? Colors.red : Colors.green,
                    ),
                    onPressed: () {
                      setState(() {
                        doctor['is_active'] = !doctor['is_active'];
                      });

                      // إرسال التحديث للسيرفر
                      updateDoctor(doctor["_id"], isActive: doctor['is_active']);

                      // عرض SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            doctor['is_active']
                                ? "تم تفعيل الحساب"
                                : "تم إلغاء تنشيط الحساب",
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // عرض السيرة الذاتية
              if (cvUrl != null)
                Card(
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text("عرض السيرة الذاتية"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerPage(url: cvUrl),
                        ),
                      );
                    },
                  ),
                ),

// زر الموافقة
              if (widget.onApprove != null && doctor['is_approved'] != true)
                Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.check),
                    title: const Text(
                      "موافق",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("تأكيد"),
                          content: const Text("هل تريد الموافقة على هذا الحساب؟"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("لا"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);

                                // تحديث الحالة محليًا
                                setState(() {
                                  doctor['is_approved'] = true;
                                });

                                // استدعاء دالة الموافقة الأصلية
                                widget.onApprove!();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("تمت الموافقة على الحساب"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text("نعم"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),



              // زر حذف الدكتور
              Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    "Delete the doctor",
                    style: TextStyle(
                      color: Colors.red,      // اللون أحمر
                      fontWeight: FontWeight.bold, // عريض
                    ),
                  ),
                  onTap: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Confirm deletion"),
                        content: const Text("Are you sure to delete this doctor's account?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("no")),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("yes")),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      deleteDoctor(doctor["_id"]);
                      Navigator.pop(context); // الرجوع للقائمة بعد الحذف
                    }
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
