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
  Future<void> handleCancellation(Map app, {required bool approve}) async {
    final appointmentId = app['appointment_id'];

    // رابط جديد للبروت
    final url = Uri.parse("$baseUrl1/appointments/cancel/approve/$appointmentId");

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({"approve": approve}), // إرسال approve في body
      );

      if (res.statusCode == 200) {
        setState(() {
          app['status'] = approve ? "Cancelled" : "Rejected";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? "Cancellation approved" : "Cancellation rejected",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Request error: ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  final ButtonStyle smallButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size(60, 30),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    textStyle: const TextStyle(fontSize: 12),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );











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

        print("🚀 Appointments: $appointments");

        checkAndMarkCompleted();

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
    app['status'] == 'Pending').toList();
  }

  List getCancellationRequests() {
    return appointments.where((app) =>
    app['status'] == 'PendingCancellation' || app['status'] == 'Cancelled' || app['status'] == 'Rejected'
    ).toList();
  }

  Widget buildAppointmentsList(List apps) {
    if (apps.isEmpty) return const Center(child: Text("No appointments available"));
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final patientName = app['patient_name'] ?? "-";
        final dateTimeStr = app['date_time'] ?? "-";
        final reason = app['reason'] ?? "-";
        DateTime? parsedDate;
        try { parsedDate = DateTime.parse(dateTimeStr); } catch (_) { parsedDate = null; }
        final bool isExpired =
            parsedDate != null && DateTime.now().isAfter(parsedDate);

        String displayStatus = app['status'] ?? "-";
        if (isExpired) {
          displayStatus = "Running out of time";
      } else if (app['status'] == "Confirmed") {
          displayStatus = "Approved";
        } else if (app['status'] == "Rejected") {
          displayStatus = "Rejected";
        } else if (app['status'] == "Completed") {
          displayStatus = "Completed";
        } else if (app['status'] == "Cancelled") {
          displayStatus = "Cancelled";
        } else if (app['status'] == "Pending") {
          displayStatus = "Pending Doctor Approval";
        }

        return Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Patient: $patientName"),
                Text('Time: ${parsedDate != null ? DateFormat("yyyy-MM-dd HH:mm").format(parsedDate) : "-"}'),
                Text('Status: $displayStatus'),
                if(reason != "-") Text('Reason: $reason', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),

                Row(

                  children: [
                    if (isExpired)
                      IconButton(
                        onPressed: () => deleteAppointment(app['appointment_id']),
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                    if (app['status'] == 'Completed')
                      IconButton(
                        onPressed: () => deleteAppointment(app['appointment_id']),
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: "Delete appointment",
                      ),

                    if (app['status'] == "Pending") ...[
                      ElevatedButton(
                        onPressed: () => handleApproval(app, approve: true),
                        style: smallButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(Colors.green),
                        ),
                        child: const Text("Approve"),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () => handleApproval(app, approve: false),
                        style: smallButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(Colors.red),
                        ),
                        child: const Text("Reject"),
                      ),
                    ]

                    else if (app['status'] == "Confirmed") ...[
                      ElevatedButton(
                        onPressed: () => markCompleted(app, index),
                        style: smallButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(Colors.blue),
                        ),
                        child: const Text("Completed"),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () => handleApproval(app, revert: true),
                        style: smallButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(Colors.orange),
                        ),
                        child: const Text("Revert"),
                      ),
                    ]

                    else if (app['status'] == "Rejected") ...[
                        ElevatedButton(
                          onPressed: () => handleApproval(app, revert: true),
                          style: smallButtonStyle.copyWith(
                            backgroundColor: MaterialStateProperty.all(Colors.orange),
                          ),
                          child: const Text("Revert"),
                        ),
                      ],

                    if (app['status'] == "PendingCancellation") ...[
                      ElevatedButton(
                        onPressed: () => handleCancellation(app, approve: true),
                        style: smallButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(Colors.green),
                        ),
                        child: const Text("Approve Cancel"),
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

  Future<void> handleApproval(Map app, {bool? approve, bool revert = false}) async {
    final appointmentId = app['appointment_id'];

    // إعداد query parameters
    Map<String, String> queryParams = {};
    if (approve != null) queryParams['approve'] = approve.toString();
    queryParams['revert'] = revert.toString(); // دائمًا نرسل revert

    Uri url = Uri.parse("$baseUrl1/appointments/approve/$appointmentId")
        .replace(queryParameters: queryParams);

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        // لا ترسل body
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(revert
                ? "Appointment reverted to Pending"
                : (approve == true ? "Approved" : "Rejected")),
          ),
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
          SnackBar(content: Text("An error occurred: ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }



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
          const SnackBar(content: Text("Appointment marked as completed")),
        );
        setState(() {
          app['status'] = "Completed";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    final url = Uri.parse('$baseUrl1/appointments/delete/$appointmentId');
    try {
      final res = await http.delete(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          });

      if (res.statusCode == 200) {
        print("✅ Appointment deleted $appointmentId");
        fetchAppointments();
      } else {
        print("❌ Error deleting appointment $appointmentId");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

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
            Tab(text: "Confirmed / Completed"),
            Tab(text: "Outstanding"),
            Tab(text: "Cancellation Requests"),
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
