import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'AdminPatientProfilePage.dart';

class AdminPatientListPage extends StatefulWidget {
  const AdminPatientListPage({super.key});

  @override
  State<AdminPatientListPage> createState() => _AdminPatientListPageState();
}

class _AdminPatientListPageState extends State<AdminPatientListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List patients = [];
  bool loading = false;
  final String baseUrl = "http://10.0.2.2:8000"; // API

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchPatients();
  }

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

  // ------------------ تفعيل/إيقاف الحساب مباشرة ------------------
  Future<void> toggleActive(Map patient) async {
    final patientId = patient["_id"];
    final currentStatus = patient["is_active"] ?? true;

    setState(() => loading = true);
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/patient/$patientId/toggle_active"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"is_active": !currentStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          patient["is_active"] = !currentStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus
                ? "تم تفعيل الحساب ✅"
                : "تم إلغاء تفعيل الحساب ❌"),
          ),
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

  List getActivePatients() =>
      patients.where((p) => p["is_active"] == true).toList();
  List getInactivePatients() =>
      patients.where((p) => p["is_active"] == false).toList();

  Widget buildPatientList(List list) {
    if (list.isEmpty) return const Center(child: Text("لا يوجد مرضى"));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final patient = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text("${patient["first_name"]} ${patient["last_name"]}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient["email"] ?? ""),
                Text(patient["is_active"] ? "Active " : "Not Active "),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                patient["is_active"] ? Icons.pause : Icons.play_arrow,
                color: patient["is_active"] ? Colors.red : Colors.green,
              ),
              onPressed: () => toggleActive(patient),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AdminPatientProfilePage(patient: patient),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("قائمة المرضى"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "المرضى النشطين"),
            Tab(text: "المرضى الغير نشطين"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          buildPatientList(getActivePatients()),
          buildPatientList(getInactivePatients()),
        ],
      ),
    );
  }
}
