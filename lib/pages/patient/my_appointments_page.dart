import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../core/config/app_font.dart';
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
    final url = Uri.parse(myAppointmentsUrl);
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
    final url = Uri.parse(cancelAppointmentUrl + appointmentId);
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
      child: isLoading
          ? Center(
        child: CircularProgressIndicator(color: AppTheme.patientPrimary),
      )
          : appointments.isEmpty
          ? Center(
        child: Text(
          'No appointments at the moment',
          style: AppFont.regular(
            size: 16,
            weight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "👨‍⚕️ Doctor: ${appt['doctor_name'] ?? '-'}",
                    style: AppFont.regular(
                      size: 18,
                      weight: FontWeight.w600,
                      color: AppTheme.patientText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "🕒 Date: ${appt['date_time'] ?? '-'}",
                    style: AppFont.regular(
                      size: 14,
                      color: AppTheme.patientText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "📋 Status: $status",
                    style: AppFont.regular(
                      size: 14,
                      weight:
                      isPending ? FontWeight.w600 : FontWeight.w400,
                      color: isPending ? Colors.orange : AppTheme.patientText,
                    ),
                  ),
                   SizedBox(height: 4),
                  Text(
                    "📝 Reason: ${appt['reason'] ?? '-'}",
                    style: AppFont.regular(
                      size: 14,
                      color: AppTheme.patientText,
                    ),
                  ),
                   SizedBox(height: 10),
                  if (!isPending)
                    ElevatedButton.icon(
                      onPressed: () =>
                          requestCancel(appt['appointment_id']),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Request Cancellation'),
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