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

  void updateAvailableTimes() {
    if (selectedDoctorId == null || selectedDate == null) return;

    final doctor = doctors.firstWhere((d) => d['id'] == selectedDoctorId);
    final workHours =
        doctor['work_hours']?.split('-').map((s) => s.trim()).toList() ??
            ['09:00', '17:00'];

    final startHour = int.parse(workHours[0].split(':')[0]);
    final endHour = int.parse(workHours[1].split(':')[0]);

    List<String> times = [];
    for (int h = startHour; h <= endHour; h++) {
      times.add('${h.toString().padLeft(2, '0')}:00');
      if (h != endHour) times.add('${h.toString().padLeft(2, '0')}:30');
    }

    final now = DateTime.now();
    if (selectedDate!.day == now.day &&
        selectedDate!.month == now.month &&
        selectedDate!.year == now.year) {
      times = times.where((t) {
        final parts = t.split(':');
        final dt = DateTime(selectedDate!.year, selectedDate!.month,
            selectedDate!.day, int.parse(parts[0]), int.parse(parts[1]));
        return dt.isAfter(now);
      }).toList();
    }

    setState(() {
      availableTimes = times;
      selectedTime = null;
    });
  }

  Future<void> pickDate() async {
    if (selectedDoctorId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('اختر الطبيب أولاً')));
      return;
    }

    final doctor = doctors.firstWhere((d) => d['id'] == selectedDoctorId);
    final allowedDays =
        (doctor['days'] as List?)?.cast<String>() ?? ["Monday", "Tuesday"];

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (date) {
        String dayName = DateFormat('EEEE').format(date);
        return allowedDays.contains(dayName);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
            ColorScheme.light(primary: Colors.pink.shade400, surface: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        updateAvailableTimes();
      });
    }
  }

  Future<void> bookAppointment() async {
    if (selectedDoctorId == null ||
        selectedDate == null ||
        selectedTime == null ||
        reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('يرجى تعبئة جميع الحقول')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final timeParts = selectedTime!.split(':');
      final dateTime = DateTime(selectedDate!.year, selectedDate!.month,
          selectedDate!.day, int.parse(timeParts[0]), int.parse(timeParts[1]));

      final uri = Uri.parse(AppointmentsBook).replace(queryParameters: {
        "doctor_id": selectedDoctorId!,
        "date_time": dateTime.toIso8601String(),
        "reason": reasonController.text,
      });

      final res = await http.post(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم الحجز بنجاح')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحجز: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ خطأ: $e')));
    } finally {
      setState(() => isLoading = false);
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
                    '${doc['name']} - ${doc['specialization'] ?? ''}',
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
                trailing: const Icon(Icons.calendar_today,
                    color: Colors.pinkAccent),
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
                      onTap: () =>
                          setState(() => selectedTime = time),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.pinkAccent
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? Colors.pinkAccent.withOpacity(0.4)
                                  : Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            )
                          ],
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87),
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
                  gradient: const LinearGradient(
                    colors: [Colors.pinkAccent, Colors.orangeAccent],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.pinkAccent,
                        offset: Offset(0, 4),
                        blurRadius: 10)
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 24),
                alignment: Alignment.center,
                child: const Text(
                  "تأكيد الحجز",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
