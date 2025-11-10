import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../core/config/theme.dart';


class MyAppointmentsPage extends StatefulWidget {
  final String token;

  const MyAppointmentsPage({super.key, required this.token});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  List appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyAppointments();
  }

  Future<void> fetchMyAppointments() async {
    final url = Uri.parse(AppointmentsMy);
    try {
      final res = await http.get(url, headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json",
      });

      if (res.statusCode == 200) {
        setState(() {
          appointments = json.decode(utf8.decode(res.bodyBytes));
          isLoading = false;
        });
      } else {
        throw Exception("فشل في جلب المواعيد");
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب المواعيد: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> requestCancel(String appointmentId) async {
    final url = Uri.parse(AppointmentsCancel + appointmentId);
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
            content: Text(data["message"]),
            backgroundColor: Colors.green,
          ),
        );
        fetchMyAppointments();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء الطلب'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child:isLoading
          ?  Center(child: CircularProgressIndicator(color:AppTheme.patientPrimary))
          : appointments.isEmpty
          ?  Center(
        child: Text(
          'No appointments at the moment ',
          style: TextStyle(fontSize: 16, foreground: Paint()..shader = LinearGradient(
            colors: [Colors.black, Colors.pinkAccent.shade200],
          ).createShader(Rect.fromLTWH(0, 0, 200, 50)),fontWeight: FontWeight.w500),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appt = appointments[index];
          final status = appt['status'] ?? '-';
          final isPending = status == 'PendingCancellation';
          return Card(
            color: AppTheme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                "👨‍⚕️ الطبيب: ${appt['doctor_name'] ?? '-'}",
                style:  TextStyle(
                  color:AppTheme.patientText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🕒 التاريخ: ${appt['date_time'] ?? '-'}",
                      style:  TextStyle(color: AppTheme.patientText)),
                  Text("📋 الحالة: $status",
                      style: TextStyle(
                          color: isPending ? Colors.orange : AppTheme.patientText,
                          fontWeight: isPending ? FontWeight.bold : FontWeight.normal)),
                  Text("📝 السبب: ${appt['reason'] ?? '-'}",
                      style:  TextStyle(color: AppTheme.patientText)),
                  const SizedBox(height: 10),
                  if (!isPending)
                    ElevatedButton.icon(
                      onPressed: () => requestCancel(appt['appointment_id']),
                      icon: const Icon(Icons.cancel),
                      label: const Text('طلب إلغاء الموعد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
