import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/app_config.dart';
import 'dart:async';

class DoctorAppointmentsPage extends StatefulWidget {
  final String token;
  const DoctorAppointmentsPage({super.key, required this.token});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  List appointments = [];
  bool isLoading = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchAppointments();
    timer = Timer.periodic(const Duration(seconds: 25), (_) => fetchAppointments());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchAppointments() async {
    setState(() => isLoading = true);
    final url = Uri.parse(AppointmentsDoctor);
    try {
      final res = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      });

      if (res.statusCode == 200) {
        setState(() {
          appointments = json.decode(utf8.decode(res.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List getConfirmedOrCompletedAppointments() {
    return appointments.where((app) =>
    app['status'] == 'Confirmed' || app['status'] == 'Completed').toList();
  }

  List getPendingOrCancelledAppointments() {
    return appointments.where((app) =>
    app['status'] == 'Pending' ||
        app['status'] == 'Cancelled' ||
        app['status'] == 'Rejected').toList();
  }

  // **طلبات إلغاء الحجز**
  List getCancellationRequests() {
    return appointments.where((app) => app['status'] == 'PendingCancellation').toList();
  }

  Widget buildAppointmentsList(List apps, {bool showCancelActions = false}) {
    if (apps.isEmpty) return const Center(child: Text("لا يوجد مواعيد"));
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final patientName = app['patient_name'] ?? "-";
        final dateTimeStr = app['date_time'] ?? "-";
        final status = app['status'] ?? "-";
        DateTime? parsedDate;
        try { parsedDate = DateTime.parse(dateTimeStr); } catch (_) { parsedDate = null; }

        return Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("المريض: $patientName"),
              Text('الوقت: ${parsedDate != null ? DateFormat("yyyy-MM-dd HH:mm").format(parsedDate) : "-"}'),
              Text('الحالة: $status'),
              if (showCancelActions) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => respondToCancellation(app['appointment_id'], true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("قبول الإلغاء"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => respondToCancellation(app['appointment_id'], false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("رفض الإلغاء"),
                    ),
                  ],
                )
              ]
            ]),
          ),
        );
      },
    );
  }

  Future<void> respondToCancellation(String appointmentId, bool approve) async {
    final url = Uri.parse('$AppointmentsDoctor/approve/$appointmentId');
    try {
      final res = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode({"approve": approve}));

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? "تم قبول الإلغاء" : "تم رفض الإلغاء")),
        );
        fetchAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ أثناء معالجة الإلغاء")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // عدد التبويبات الآن أصبح 3
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: "المؤكدة/المنجزة"),
              Tab(text: "الملغاة/المعلقة"),
              Tab(text: "طلبات الإلغاء"),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchAppointments,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                children: [
                  buildAppointmentsList(getConfirmedOrCompletedAppointments()),
                  buildAppointmentsList(getPendingOrCancelledAppointments()),
                  buildAppointmentsList(getCancellationRequests(), showCancelActions: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
