import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AdminDoctorProfilePage.dart';

class AdminDoctorListPage extends StatefulWidget {
  const AdminDoctorListPage({super.key});

  @override
  State<AdminDoctorListPage> createState() => _AdminDoctorListPageState();
}

class _AdminDoctorListPageState extends State<AdminDoctorListPage>
    with SingleTickerProviderStateMixin {
  List doctors = [];
  bool loading = true;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    fetchDoctors();
  }

  // جلب الدكاترة من السيرفر
  Future<void> fetchDoctors() async {
    setState(() => loading = true);
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

  // بطاقة كل طبيب
  Widget doctorCard(Map doctor, {bool showApprove = false, bool showActive = false}) {
    final cvUrl = doctor['cv_url'];

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text("${doctor['first_name']} ${doctor['last_name']}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${doctor['email']}"),
            if (showActive) Text("Active: ${doctor['is_active']}"),
            if (showApprove) Text("Approved: ${doctor['is_approved']}"),
          ],
        ),
        trailing: Column(
          children: [
            if (showApprove)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorProfilePage(
                        doctor: doctor,
                        onApprove: () => updateDoctor(doctor["_id"], isApproved: true),
                      ),
                    ),
                  );
                },
              ),
            if (showActive)
              IconButton(
                icon: Icon(
                  doctor['is_active'] ? Icons.pause : Icons.play_arrow,
                  color: doctor['is_active'] ? Colors.red : Colors.green,
                ),
                onPressed: () => updateDoctor(
                    doctor["_id"], isActive: !doctor['is_active']),
              ),
          ],
        ),
        onTap: cvUrl != null
            ? () async {
          if (cvUrl.endsWith(".pdf")) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerPage(url: cvUrl),
              ),
            );
          } else {
            final uri = Uri.parse(cvUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("لا يمكن فتح الملف")),
              );
            }
          }
        }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("قائمة الدكاترة"),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: "طلبات الموافقة"),
            Tab(text: "الدكاترة"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: tabController,
        children: [
          // Tab 1: طلبات الموافقة
          ListView(
            children: doctors
                .where((d) => d['is_approved'] == false)
                .map((d) => doctorCard(d, showApprove: true))
                .toList(),
          ),
          // Tab 2: الدكاترة النشطين / غير النشطين
          ListView(
            children: doctors
                .map((d) => doctorCard(d, showActive: true))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ================= PDF Viewer =================
class PdfViewerPage extends StatefulWidget {
  final String url;

  const PdfViewerPage({super.key, required this.url});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfControllerPinch? controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode == 200) {
        controller = PdfControllerPinch(
          document: PdfDocument.openData(response.bodyBytes),
        );
      } else {
        throw Exception("خطأ في تحميل الملف");
      }
    } catch (e) {
      print("❌ PDF Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل تحميل PDF")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("عرض CV")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : controller == null
          ? const Center(child: Text("لا يمكن فتح الملف"))
          : PdfViewPinch(controller: controller!),
    );
  }
}

// ================= صفحة الطبيب =================
class DoctorProfilePage extends StatelessWidget {
  final Map doctor;
  final Function()? onApprove;

  const DoctorProfilePage({super.key, required this.doctor, this.onApprove});

  @override
  Widget build(BuildContext context) {
    final cvUrl = doctor['cv_url'];

    return Scaffold(
      appBar: AppBar(title: Text("${doctor['first_name']} ${doctor['last_name']}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${doctor['email']}"),
            Text("Phone: ${doctor['phone_number'] ?? '-'}"),
            Text("Approved: ${doctor['is_approved']}"),
            const SizedBox(height: 20),
            if (cvUrl != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("عرض السيرة الذاتية"),
                onPressed: () async {
                  if (cvUrl.endsWith(".pdf")) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PdfViewerPage(url: cvUrl)));
                  } else {
                    final uri = Uri.parse(cvUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
              ),
            const Spacer(),
            if (onApprove != null)
              ElevatedButton(
                onPressed: onApprove,
                child: const Text("موافق"),
              ),
          ],
        ),
      ),
    );
  }
}
