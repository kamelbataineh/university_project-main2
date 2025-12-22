import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/app_config.dart';
import '../../core/config/app_font.dart';
import '../../core/config/theme.dart';

class BookAppointmentPageDoctor extends StatefulWidget {
  final String token;
  final String doctorId;
  final String doctorName;

  const BookAppointmentPageDoctor({
    super.key,
    required this.token,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<BookAppointmentPageDoctor> createState() => _BookAppointmentPageDoctorState();
}

class _BookAppointmentPageDoctorState extends State<BookAppointmentPageDoctor> {
  DateTime? selectedDate;
  String? selectedTime;
  TextEditingController reasonController = TextEditingController();
  List<String> availableTimes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }
  Future<void> pickDate() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1)); // البداية من الغد

    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow, // ممنوع اليوم
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.pinkAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
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
      fetchAvailableTimes();
    }
  }


  Future<void> fetchAvailableTimes() async {
    if (selectedDate == null) return;

    final dateStr =
        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2,'0')}-${selectedDate!.day.toString().padLeft(2,'0')}";
    try {
      // جلب كل الأوقات المتاحة
      final response = await http.get(
        Uri.parse('$availableSlotsUrl/${widget.doctorId}?date=$dateStr'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // جلب المواعيد المحجوزة لنفس اليوم
        final bookedResponse = await http.get(
          Uri.parse(myAppointmentsUrl + "?doctor_id=${widget.doctorId}&date=$dateStr"),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        final bookedData = bookedResponse.statusCode == 200
            ? jsonDecode(bookedResponse.body)
            : [];

        // فلترة الأوقات المحجوزة
        List<String> bookedTimes = [];
        for (var appt in bookedData) {
          final dt = DateTime.parse(appt['date_time']);
          bookedTimes.add("${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}");
        }

        setState(() {
          availableTimes = List<String>.from(data)
              .where((time) => !bookedTimes.contains(time))
              .toList();
        });
      } else {
        print("❌ Failed to fetch slots: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching slots: $e");
    }
  }

  Future<void> bookAppointment() async {
    // تحقق من اختيار التاريخ والوقت
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date and time")),
      );
      return;
    }

    // تحقق أن الوقت لا يزال متاح
    if (!availableTimes.contains(selectedTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This time is already booked, please select another time."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      int.parse(selectedTime!.split(":")[0]),
      int.parse(selectedTime!.split(":")[1]),
    );

    // تحقق من وجود موعد مسبق للمريض
    try {
      final existingAppointmentsResponse = await http.get(
        Uri.parse(myAppointmentsUrl),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      final existingAppointments = existingAppointmentsResponse.statusCode == 200
          ? json.decode(existingAppointmentsResponse.body)
          : [];

      if (existingAppointments.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You already have an appointment booked."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // يمنع الحجز
      }

      // متابعة الحجز
      final response = await http.post(
        Uri.parse(bookAppointmentUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "doctor_id": widget.doctorId,
          "date_time": dateTime.toIso8601String(),
          "reason": reasonController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment booked successfully 🌸")),
        );
        setState(() {
          availableTimes.remove(selectedTime); // إزالة الوقت المحجوز
          selectedTime = null;
          reasonController.clear();
        });
      } else {
        print("❌ Booking failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to book appointment")),
        );
      }
    } catch (e) {
      print("❌ Error booking appointment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error booking appointment: $e")),
      );
    }
  }


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
          BoxShadow(
              color: Colors.black12, offset: Offset(4, 4), blurRadius: 10),
          BoxShadow(
              color: Colors.white70, offset: Offset(-4, -4), blurRadius: 10),
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
        title: Text(
          "Book Appointment",
          style: AppFont.regular(
            size: 18,
            weight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            neumorphicCard(
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.pinkAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Doctor: ${widget.doctorName}",
                      style: AppFont.regular(
                        size: 16,
                        weight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 📅 اختيار التاريخ
            neumorphicCard(
              child: ListTile(
                title: Text(
                  selectedDate == null
                      ? "Select Date"
                      : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  style: AppFont.regular(
                    size: 14,
                    weight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                trailing: const Icon(
                    Icons.calendar_today, color: Colors.pinkAccent),
                onTap: pickDate,
              ),
            ),
            const SizedBox(height: 20),
            // ⏰ الأوقات المتاحة
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.patientElevatedButtonbackgroundColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? Colors.pinkAccent.withOpacity(0.4)
                                  : Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),
            // 📝 سبب الزيارة
            neumorphicCard(
              child: TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: "Reason for Visit",
                  hintText: "Describe your symptoms or reason for booking...",
                  labelStyle: AppFont.regular(size: 14, color: Colors.black54),
                  hintStyle: AppFont.regular(size: 14, color: Colors.black38),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: bookAppointment,
                child: Container(
                  height: 48,
                  width: MediaQuery.of(context).size.width / 2.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.patientElevatedButtonbackgroundColor.withOpacity(0.9),
                        AppTheme.patientElevatedButtonbackgroundColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.35),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.18),
                        offset: const Offset(-2, -2),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Confirm Booking",
                    style: AppFont.regular(
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),

          ],
        ),
      ),
    );
  }
}