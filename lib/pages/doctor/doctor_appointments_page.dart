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
    timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchAppointments());
  }

  @override
  void dispose() {
    timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ------------------ جلب المواعيد ------------------
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

        // ✅ بعد جلب المواعيد، تحقق من انتهاء المواعيد وحذفها
        checkAndDeleteAppointments();

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
    ).toList(); // المواعيد الملغاة أو رفض الطلب
  }

  // ------------------ بناء القائمة ------------------
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
          app['status'] = "Completed"; // تحديث الحالة لمنع ظهور الزر
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

                // ------------------ أزرار حسب الحالة ------------------
                Row(
                  children: [
                    if (app['status'] == "Pending") ...[
                      ElevatedButton(
                        onPressed: () => handleApproval(app, approve: true, index: index),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child:  const Text("موافقة"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => handleApproval(app, approve: false, index: index),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child:  const Text("رفض"),
                      ),
                    ] else if (app['status'] == "Confirmed") ...[
                      ElevatedButton(
                        onPressed: () => markCompleted(app, index),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text("تم الإنجاز"),
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

  // ------------------ التعامل مع الموافقة/الرفض ------------------
  Future<void> handleApproval(Map app, {required bool approve, required int index}) async {
    final appointmentId = app['appointment_id'];
    final url = Uri.parse("$baseUrl1/appointments/approve/$appointmentId?approve=$approve");

    try {
      final res = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          });

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? "تمت الموافقة" : "تم الرفض")),
        );

        setState(() {
          if (approve) {
            app['status'] = "Confirmed";
          } else {
            app['status'] = "PendingCancellation";
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

        // حذف تلقائي بعد 30 دقيقة
        Future.delayed(const Duration(minutes: 30), () => deleteAppointment(app['appointment_id']));

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
    final url = Uri.parse('$baseUrl1/appointments/delete/$appointmentId'); // ضع رابط الحذف الصحيح
    try {
      final res = await http.delete(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          });

      if (res.statusCode == 200) {
        print("✅ تم حذف الموعد $appointmentId تلقائياً");
        fetchAppointments();
      } else {
        print("❌ حدث خطأ أثناء حذف الموعد $appointmentId");
      }
    } catch (e) {
      print("❌ خطأ: $e");
    }
  }

  // ------------------ فحص المواعيد المنتهية ------------------
  void checkAndDeleteAppointments() {
    for (var app in appointments) {
      DateTime? dateTime;
      try {
        dateTime = DateTime.parse(app['date_time']);
      } catch (_) {}

      if (dateTime != null) {
        if (app['status'] == 'Completed') {
          final deleteTime = dateTime.add(const Duration(minutes: 30));
          if (DateTime.now().isAfter(deleteTime)) {
            deleteAppointment(app['appointment_id']);
          }
        } else if (app['status'] == 'Confirmed') {
          if (DateTime.now().isAfter(dateTime)) {
            app['status'] = 'Completed';
            markCompleted(app, 0);
          }
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
            Tab(text: "المؤكدة/المنجزة"),
            Tab(text: "المعلقة"),
            Tab(text: "طلبات الإلغاء"),
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

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../core/config/app_config.dart';
// import 'dart:async';
//
// class DoctorAppointmentsPage extends StatefulWidget {
//   final String token;
//   const DoctorAppointmentsPage({super.key, required this.token});
//
//   @override
//   State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
// }
//
// class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> with SingleTickerProviderStateMixin {
//   List appointments = [];
//   bool isLoading = true;
//   Timer? timer;
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     fetchAppointments();
//     timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchAppointments());
//   }
//
//   @override
//   void dispose() {
//     timer?.cancel();
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   Future<void> fetchAppointments() async {
//     setState(() => isLoading = true);
//     final url = Uri.parse(doctorAppointmentsUrl);
//     try {
//       final res = await http.get(url, headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer ${widget.token}',
//       });
//
//       if (res.statusCode == 200) {
//         setState(() {
//           appointments = json.decode(utf8.decode(res.bodyBytes));
//           isLoading = false;
//         });
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }
//
//   // ------------------ تصفية المواعيد حسب التبويب ------------------
//   List getConfirmedOrCompletedAppointments() {
//     return appointments.where((app) =>
//     app['status'] == 'Confirmed' || app['status'] == 'Completed').toList();
//   }
//   List getPendingOrCancelledAppointments() {
//     return appointments.where((app) =>
//     app['status'] == 'Pending').toList(); // فقط المواعيد المعلقة
//   }
//
//   List getCancellationRequests() {
//     return appointments.where((app) =>
//     app['status'] == 'PendingCancellation' || app['status'] == 'Cancelled' || app['status'] == 'Rejected'
//     ).toList(); // كل المواعيد الملغاة أو رفض الطلب
//   }
//
//   // ------------------ بناء القائمة ------------------
//   Widget buildAppointmentsList(List apps) {
//     if (apps.isEmpty) return const Center(child: Text("لا يوجد مواعيد"));
//     return ListView.builder(
//       itemCount: apps.length,
//       itemBuilder: (context, index) {
//         final app = apps[index];
//         final patientName = app['patient_name'] ?? "-";
//         final dateTimeStr = app['date_time'] ?? "-";
//         final reason = app['reason'] ?? "-";
//         DateTime? parsedDate;
//         try { parsedDate = DateTime.parse(dateTimeStr); } catch (_) { parsedDate = null; }
//
//         // ------------------ تحديث الحالة بالعربي ------------------
//         // ------------------ تحديث الحالة بالعربي ------------------
//         String displayStatus = app['status'] ?? "-";
//         if (parsedDate != null && DateTime.now().isAfter(parsedDate) && app['status'] == "Confirmed") {
//           displayStatus = "انتهى الموعد";
//           app['status'] = "Completed"; // ✅ هنا نحدث الحالة في الداتا لمنع ظهور الزر
//         } else if (app['status'] == "Confirmed") {
//           displayStatus = "تمت الموافقة";
//         } else if (app['status'] == "Rejected") {
//           displayStatus = "تم الرفض";
//         } else if (app['status'] == "Completed") {
//           displayStatus = "تم الإنجاز";
//         } else if (app['status'] == "Cancelled") {
//           displayStatus = "ملغى";
//         } else if (app['status'] == "Pending") {
//           displayStatus = "في انتظار موافقة الدكتور";
//         }
//
//
//         return Card(
//           margin: const EdgeInsets.all(10),
//           child: Padding(
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("المريض: $patientName"),
//                 Text('الوقت: ${parsedDate != null ? DateFormat("yyyy-MM-dd HH:mm").format(parsedDate) : "-"}'),
//                 Text('الحالة: $displayStatus'),
//                 if(reason != "-") Text('السبب: $reason', style: const TextStyle(color: Colors.grey)),
//                 const SizedBox(height: 10),
//
//                 // ------------------ أزرار حسب الحالة ------------------
//                 Row(
//                   children: [
//                     if (app['status'] == "Pending") ...[
//                       ElevatedButton(
//                         onPressed: () => handleApproval(app, approve: true, index: index),
//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                         child:  Text("موافقة"),
//                       ),
//                        SizedBox(width: 10),
//                       ElevatedButton(
//                         onPressed: () => handleApproval(app, approve: false, index: index),
//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                         child:  Text("رفض"),
//                       ),
//                     ] else if (app['status'] == "Confirmed") ...[
//                       ElevatedButton(
//                         onPressed: () => markCompleted(app, index),
//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//                         child: const Text("تم الإنجاز"),
//                       ),
//                     ],
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // ------------------ التعامل مع الموافقة/الرفض ------------------
//   Future<void> handleApproval(Map app, {required bool approve, required int index}) async {
//     final appointmentId = app['appointment_id'];
//     final url = Uri.parse("$baseUrl1/appointments/approve/$appointmentId?approve=$approve");
//
//     try {
//       final res = await http.post(url,
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer ${widget.token}',
//           });
//
//       if (res.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(approve ? "تمت الموافقة" : "تم الرفض")),
//         );
//
//         setState(() {
//           if (approve) {
//             app['status'] = "Confirmed";
//           } else {
//             app['status'] = "PendingCancellation";
//           }
//         });
//
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("حدث خطأ")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ خطأ: $e")),
//       );
//     }
//   }
//
//
//   // ------------------ تعليم الموعد كمكتمل ------------------
//   Future<void> markCompleted(Map app, int index) async {
//     final appointmentId = app['appointment_id'];
//     final url = Uri.parse('$completeAppointmentUrl/$appointmentId');
//
//     try {
//       final res = await http.post(url,
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer ${widget.token}',
//           });
//
//       if (res.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("تم تعليم الموعد كمكتمل")),
//         );
//         setState(() {
//           app['status'] = "Completed";
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("حدث خطأ")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ خطأ: $e")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: "المؤكدة/المنجزة"),
//             Tab(text: "المعلقة"),
//             Tab(text: "طلبات الإلغاء"),
//           ],
//         ),
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: fetchAppointments,
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : TabBarView(
//               controller: _tabController,
//               children: [
//                 buildAppointmentsList(getConfirmedOrCompletedAppointments()),
//                 buildAppointmentsList(getPendingOrCancelledAppointments()),
//                 buildAppointmentsList(getCancellationRequests()),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
