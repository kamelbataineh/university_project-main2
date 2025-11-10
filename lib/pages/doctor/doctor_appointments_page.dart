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

  // ------------------- جلب مواعيد المرضى -------------------
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل تحميل المواعيد: ${res.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e")),
      );
    }
  }

  // ------------------- موافقة وحذف الموعد -------------------
  Future<void> approveCancel(String appointmentId) async {
    final url = Uri.parse(AppointmentsApprove + appointmentId);
    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${data["message"]}'),
            backgroundColor: Colors.green,
          ),
        );
        fetchAppointments();
      } else {
        final error = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error["detail"] ?? "حدث خطأ"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('حدث خطأ أثناء الموافقة'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Icon getStatusIcon(String status) {
    switch (status) {
      case "Cancelled":
      case "Rejected":
        return const Icon(Icons.cancel, color: Colors.red);
      case "Completed":
        return const Icon(Icons.check, color: Colors.blue);
      case "Pending":
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case "PendingCancellation":
        return const Icon(Icons.hourglass_top, color: Colors.orange);
      case "Confirmed":
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مواعيد مرضاي"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAppointments,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchAppointments,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : appointments.isEmpty
            ? const Center(child: Text("لا يوجد مواعيد"))
            : ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final app = appointments[index];
            final patientName = app['patient_name'] ?? "-";
            final dateTimeStr = app['date_time'] ?? "-";
            final status = app['status'] ?? "-";
            final reason = app['reason'] ?? "-";

            DateTime? parsedDate;
            try {
              parsedDate = DateTime.parse(dateTimeStr);
            } catch (_) {
              parsedDate = null;
            }

            return Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        getStatusIcon(status),
                        const SizedBox(width: 10),
                        Text("المريض: $patientName",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                        'الوقت: ${parsedDate != null ? DateFormat("yyyy-MM-dd HH:mm").format(parsedDate) : "-"}'),
                    Text('الحالة: $status'),
                    Text('سبب الحجز: $reason'),
                    const SizedBox(height: 10),
                    if (status == 'PendingCancellation')
                      ElevatedButton.icon(
                        onPressed: () => approveCancel(app['appointment_id']),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('موافقة وحذف الموعد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
