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
    print("🔹 initState called");
    fetchDoctors();
  }
// ===================== إضافة في _BookAppointmentPageState =====================
  // 🩺 جلب قائمة الأطباء من السيرفر
  Future<void> fetchDoctors() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(doctorsListUrl),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          doctors = data.map((doc) => {
            'id': doc['id'] ?? doc['_id'],
            'name': doc['first_name'] + " " + doc['last_name'],
            'specialty': doc['specialty'] ?? ""
          }).toList();
        });
      } else {
        print("❌ Failed to fetch doctors: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching doctors: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 📅 اختيار التاريخ
  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.pinkAccent, // لون الأزرار
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

  // ⏰ جلب الأوقات المتاحة للطبيب
  Future<void> fetchAvailableTimes() async {
    if (selectedDoctorId == null || selectedDate == null) return;

    final dateStr = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2,'0')}-${selectedDate!.day.toString().padLeft(2,'0')}";
    try {
      final response = await http.get(
        Uri.parse('$availableSlotsUrl/$selectedDoctorId?date=$dateStr'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          availableTimes = List<String>.from(data);
        });
      } else {
        print("❌ Failed to fetch slots: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching slots: $e");
    }
  }

  // ✅ حجز الموعد
  Future<void> bookAppointment() async {
    if (selectedDoctorId == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("رجاءً اختر الطبيب والتاريخ والوقت")),
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

    try {
      final response = await http.post(
        Uri.parse(bookAppointmentUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "doctor_id": selectedDoctorId,
          "date_time": dateTime.toIso8601String(),
          "reason": reasonController.text
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حجز الموعد بنجاح 🌸")),
        );
        setState(() {
          selectedDoctorId = null;
          selectedDate = null;
          selectedTime = null;
          availableTimes = [];
          reasonController.clear();
        });
      } else {
        print("❌ Booking failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل في حجز الموعد")),
        );
      }
    } catch (e) {
      print("❌ Error booking appointment: $e");
    }
  }

  // -------------------- نيو مورفيزم كارد --------------------
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
    print("🔹 Building UI");
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
                  print("🔹 Doctor selected: $val");
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
                      onTap: () {
                        print("🔹 Time selected: $time");
                        setState(() => selectedTime = time);
                      },
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
