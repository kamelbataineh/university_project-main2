import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';

class BookAppointmentPage extends StatefulWidget {
  final String userId;
  final String token;

  const BookAppointmentPage({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  List doctors = [];
  String? selectedDoctorId;
  DateTime? selectedDate;
  String? selectedTime;
  TextEditingController reasonController = TextEditingController();
  List<String> availableTimes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  // -------------------- جلب الأطباء --------------------
  Future<void> fetchDoctors() async {
    try {
      final url = Uri.parse(AppointmentsListDoctors);
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });

      if (res.statusCode == 200) {
        setState(() {
          doctors = json.decode(utf8.decode(res.bodyBytes));
        });
      } else {
        print("⚠️ Error fetching doctors: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Exception while fetching doctors: $e");
    }
  }

  // -------------------- اختيار التاريخ --------------------
  Future<void> pickDate() async {
    if (selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الطبيب أولاً')),
      );
      return;
    }

    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد أطباء متاحون')),
      );
      return;
    }

    final doctorList = doctors.where((d) => d['id'].toString() == selectedDoctorId).toList();
    if (doctorList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الطبيب غير موجود')),
      );
      return;
    }
    final now = DateTime.now();
    DateTime firstDate = now.add(const Duration(days: 1));

// ضبط ليكون أول يوم مسموح
    while (![7, 1, 2, 3, 4].contains(firstDate.weekday)) {
      firstDate = firstDate.add(const Duration(days: 1));
    }

    final lastDate = now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (date) {
        return [7, 1, 2, 3, 4].contains(date.weekday);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.pink.shade400,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );

      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTime = null;
        availableTimes = [];
      });
      await updateAvailableTimes();
    }
  }

  // -------------------- جلب الأوقات المتاحة --------------------
  Future<void> updateAvailableTimes() async {
    if (selectedDoctorId == null || selectedDate == null) return;

    setState(() => isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final uri = Uri.parse("$AppointmentsDoctorAvailable/$selectedDoctorId")
          .replace(queryParameters: {"date": dateStr});

      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });

      print("Fetch available times status: ${res.statusCode}");
      print("Fetch available times body: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded is List) {
          final times = decoded.map((e) => e.toString()).toList();
          setState(() {
            availableTimes = times;
            selectedTime = null;
          });
        } else {
          print("⚠️ Response not a List");
          setState(() {
            availableTimes = [];
            selectedTime = null;
          });
        }
      } else {
        print("⚠️ Error fetching available times: ${res.statusCode}");
        setState(() => availableTimes = []);
      }
    } catch (e) {
      print("❌ Exception fetching times: $e");
      setState(() => availableTimes = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // -------------------- حجز الموعد --------------------
  Future<void> bookAppointment() async {
    if (selectedDoctorId == null ||
        selectedDate == null ||
        selectedTime == null ||
        reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final timeParts = selectedTime!.split(':');
      final dateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final isoDateTime = dateTime.toIso8601String().split('.').first;

      // إرسال البيانات كـ query parameters وليس body
      final uri = Uri.parse(AppointmentsBook).replace(queryParameters: {
        "doctor_id": selectedDoctorId!,
        "date_time": isoDateTime,
        "reason": reasonController.text
      });

      final res = await http.post(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });

      print("Book appointment status: ${res.statusCode}");
      print("Book appointment body: ${res.body}");

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم الحجز بنجاح')),
        );
        Navigator.pop(context);
      } else {
        final body = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحجز: ${body['detail'] ?? res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // -------------------- تصميم البطاقة --------------------
  Widget neumorphicCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF5EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(4, 4), blurRadius: 10),
          BoxShadow(color: Colors.white70, offset: Offset(-4, -4), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text("حجز موعد"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            neumorphicCard(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "اختر الطبيب",
                  border: InputBorder.none,
                ),
                value: selectedDoctorId,
                items: doctors
                    .map((doc) => DropdownMenuItem<String>(
                  value: doc['id'].toString(),
                  child: Text(
                    '${doc['name']} - ${doc['specialty'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedDoctorId = val;
                    selectedDate = null;
                    selectedTime = null;
                    availableTimes = [];
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            neumorphicCard(
              child: ListTile(
                title: Text(selectedDate == null
                    ? "اختر التاريخ"
                    : DateFormat('yyyy-MM-dd').format(selectedDate!)),
                trailing: const Icon(Icons.calendar_today, color: Colors.pinkAccent),
                onTap: pickDate,
              ),
            ),
            const SizedBox(height: 20),
            if (availableTimes.isNotEmpty)
              neumorphicCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTimes.map((time) {
                    final isSelected = selectedTime == time;
                    return GestureDetector(
                      onTap: () => setState(() => selectedTime = time),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.pinkAccent : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? Colors.pinkAccent.withOpacity(0.4) : Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          time,
                          style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),
            neumorphicCard(
              child: TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: "سبب الزيارة",
                  hintText: "صف الأعراض أو السبب للحجز...",
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: bookAppointment,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.orangeAccent]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.pinkAccent, offset: Offset(0, 4), blurRadius: 10),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                alignment: Alignment.center,
                child: const Text(
                  "تأكيد الحجز",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
