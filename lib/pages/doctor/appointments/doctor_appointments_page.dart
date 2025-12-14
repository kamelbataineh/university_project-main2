
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';
import 'dart:async';

import '../records/add_record_page.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  final String token;

  const DoctorAppointmentsPage({super.key, required this.token, required String userId});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> with SingleTickerProviderStateMixin {
  List appointments = [];
  bool isLoading = true;
  Timer? timer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAppointments();
    timer = Timer.periodic(const Duration(minutes: 100), (_) => fetchAppointments());
  }

  @override
  void dispose() {
    timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ------------------ التعامل مع طلب إلغاء الحجز ------------------
  Future<void> handleCancellation(Map app, {required bool approve}) async {
    final appointmentId = app['appointment_id'];

    Uri url = Uri.parse("$baseUrl1/appointments/cancel/$appointmentId")
        .replace(queryParameters: {
      "approve": approve.toString(),
    });

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          app['status'] = approve ? "Cancelled" : "Rejected";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? "تم الموافقة على إلغاء الحجز"
                  : "تم رفض طلب الإلغاء",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ خطأ في الطلب: ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ: $e")),
      );
    }
  }

  Future<void> fetchAppointments() async {
    setState(() => isLoading = true);
    final url = Uri.parse(doctorAppointmentsUrl);
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

        print("🚀 Appointments: $appointments"); // <-- أضف هذه السطر لتعرف اسم الحقل

        checkAndMarkCompleted();

      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }


  // ------------------ تصفية المواعيد حسب التبويب ------------------
  List getConfirmedOrCompletedAppointments() {
    return appointments.where((app) =>
    app['status'] == 'Confirmed' || app['status'] == 'Completed').toList();
  }

  List getPendingOrCancelledAppointments() {
    return appointments.where((app) =>
    app['status'] == 'Pending').toList(); // فقط المواعيد المعلقة
  }

  List getCancellationRequests() {
    return appointments.where((app) =>
    app['status'] == 'PendingCancellation' || app['status'] == 'Cancelled' || app['status'] == 'Rejected'
    ).toList();
  }

  // ------------------ بناء قائمة المواعيد ------------------
  Widget buildAppointmentsList(List apps) {
    if (apps.isEmpty) return const Center(child: Text("لا يوجد مواعيد"));
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final patientName = app['patient_name'] ?? "-";
        final dateTimeStr = app['date_time'] ?? "-";
        final reason = app['reason'] ?? "-";
        DateTime? parsedDate;
        try { parsedDate = DateTime.parse(dateTimeStr); } catch (_) { parsedDate = null; }

        // ------------------ تحديث الحالة بالعربي ------------------
        String displayStatus = app['status'] ?? "-";
        if (parsedDate != null && DateTime.now().isAfter(parsedDate) && app['status'] == "Confirmed") {
          displayStatus = "انتهى الموعد";
          app['status'] = "Completed";
        } else if (app['status'] == "Confirmed") {
          displayStatus = "تمت الموافقة";
        } else if (app['status'] == "Rejected") {
          displayStatus = "تم الرفض";
        } else if (app['status'] == "Completed") {
          displayStatus = "تم الإنجاز";
        } else if (app['status'] == "Cancelled") {
          displayStatus = "ملغى";
        } else if (app['status'] == "Pending") {
          displayStatus = "في انتظار موافقة الدكتور";
        }

        return Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("المريض: $patientName"),
                Text('الوقت: ${parsedDate != null ? DateFormat("yyyy-MM-dd HH:mm").format(parsedDate) : "-"}'),
                Text('الحالة: $displayStatus'),
                if(reason != "-") Text('السبب: $reason', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    // زر حذف الموعد المكتمل
                    if (app['status'] == 'Completed')
                      IconButton(
                        onPressed: () => deleteAppointment(app['appointment_id']),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "حذف الموعد",
                      ),

                    // أزرار الموافقة أو الرفض للمواعيد المعلقة
                    if (app['status'] == "Pending") ...[
                      ElevatedButton(
                        onPressed: () => handleApproval(app, approve: true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("موافقة"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => handleApproval(app, approve: false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text("رفض"),
                      ),
                    ] else if (app['status'] == "Confirmed") ...[
                      ElevatedButton(
                        onPressed: () => markCompleted(app, index),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text("تم الإنجاز"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => handleApproval(app, revert: true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text("إعادة إلى Pending"),
                      ),
                    ] else if (app['status'] == "Rejected") ...[
                      ElevatedButton(
                        onPressed: () => handleApproval(app, revert: true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text("إعادة إلى Pending"),
                      ),
                    ],

                    // أزرار الموافقة على طلب إلغاء الحجز
                    if (app['status'] == "PendingCancellation") ...[
                      ElevatedButton(
                        onPressed: () => handleCancellation(app, approve: true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("موافقة على الإلغاء"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => handleCancellation(app, approve: false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text("رفض الإلغاء"),
                      ),
                    ],


                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------ الموافقة أو الرفض ------------------
  Future<void> handleApproval(Map app, {bool? approve, bool revert = false}) async {
    final appointmentId = app['appointment_id'];
    Map<String, String> queryParams = {};
    if (approve != null) queryParams['approve'] = approve.toString();
    queryParams['revert'] = revert.toString();

    Uri url = Uri.parse("$baseUrl1/appointments/approve/$appointmentId")
        .replace(queryParameters: queryParams);

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(revert
                  ? "تمت إعادة الموعد إلى Pending"
                  : (approve == true ? "تمت الموافقة" : "تم الرفض"))),
        );

        setState(() {
          if (revert) {
            app['status'] = "Pending";
          } else if (approve == true) {
            app['status'] = "Confirmed";
          } else {
            app['status'] = "Rejected";
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ: $e")),
      );
    }
  }

  // ------------------ تعليم الموعد كمكتمل ------------------
  Future<void> markCompleted(Map app, int index) async {
    final appointmentId = app['appointment_id'];
    final url = Uri.parse('$completeAppointmentUrl/$appointmentId');

    try {
      final res = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          });

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تعليم الموعد كمكتمل")),
        );
        setState(() {
          app['status'] = "Completed";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ: $e")),
      );
    }
  }

  // ------------------ حذف الموعد ------------------
  Future<void> deleteAppointment(String appointmentId) async {
    final url = Uri.parse('$baseUrl1/appointments/delete/$appointmentId');
    try {
      final res = await http.delete(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          });

      if (res.statusCode == 200) {
        print("✅ تم حذف الموعد $appointmentId");
        fetchAppointments();
      } else {
        print("❌ حدث خطأ أثناء حذف الموعد $appointmentId");
      }
    } catch (e) {
      print("❌ خطأ: $e");
    }
  }

  // ------------------ تعليم المواعيد المكتملة عند انتهاء الوقت ------------------
  void checkAndMarkCompleted() {
    final now = DateTime.now();
    for (var app in appointments) {
      DateTime? dateTime;
      try {
        dateTime = DateTime.parse(app['date_time']);
      } catch (_) {}

      if (dateTime != null) {
        if (app['status'] == 'Confirmed' && now.isAfter(dateTime)) {
          setState(() {
            app['status'] = 'Completed';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Confirmed/completed"),
            Tab(text: "Outstanding"),
            Tab(text: "Cancellation requests"),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchAppointments,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                buildAppointmentsList(getConfirmedOrCompletedAppointments()),
                buildAppointmentsList(getPendingOrCancelledAppointments()),
                buildAppointmentsList(getCancellationRequests()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
