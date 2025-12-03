import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:university_project/pages/auth/doctor_login_page.dart';
import '../../core/config/app_config.dart';
import '../auth/patient_login_page.dart';
class DoctorVerifyOtpPage extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;
  final String password;
  final String phoneNumber;
  final String username;


  const DoctorVerifyOtpPage({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.phoneNumber,
    required this.username,
    Key? key
  }) : super(key: key);


  @override
  State<DoctorVerifyOtpPage> createState() => _DoctorVerifyOtpPageState();
}

class _DoctorVerifyOtpPageState extends State<DoctorVerifyOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool loading = false;
  int remainingSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      remainingSeconds = 10;
    });
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          remainingSeconds--;
        });
      }
    });
  }

  String get formattedTime {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP")),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}doctors/confirm-registration?email=${widget.email}&otp=${_otpController.text.trim()}"),
      );

      final resBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("saved_email", widget.email);

        // عرض AlertDialog مع زر موافق
        showDialog(
          context: context,
          barrierDismissible: false, // لا يمكن الإغلاق بالنقر خارج النافذة
          builder: (context) => AlertDialog(
            title: const Text("تم إرسال معلوماتك ✅"),
            content: const Text(
                "تم بعث معلوماتك للادمن، عند الموافقة سوف يصلك رسالة على الإيميل"
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // إغلاق النافذة
                  // الانتقال مباشرة لصفحة تسجيل الدخول
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginDoctorPage()),
                  );
                },
                child: const Text("موافق"),
              ),
            ],
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resBody["detail"] ?? "OTP invalid")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection failed: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  /////////////////
  /////////////////
  /////////////////
  /////////////////
  /////////////////
  Future<void> resendOtp() async {
    print("🔹 Start resendOtp for: ${widget.email}");
    setState(() => loading = true);
    print("⏳ Loading set to true");

    try {
      final url = "${baseUrl}doctors/send-otp";
      print("🌐 Sending POST request to: $url with email: ${widget.email}");

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email}),
      );

      final resBody = jsonDecode(utf8.decode(response.bodyBytes));
      print("📥 Response received: $resBody");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resBody["detail"] ?? "OTP sent again ✅")),
      );

      print("⏱ Timer restarted");
      startTimer();
    } catch (e) {
      print("❌ Exception during resend OTP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to resend OTP: $e")),
      );
    } finally {
      setState(() => loading = false);
      print("⏳ Loading set to false");
    }
  }










  Future<void> showApprovalDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false, // لا يمكن إغلاقه بالنقر خارج النافذة
      builder: (context) => AlertDialog(
        title: const Text("تم إرسال معلوماتك ✅"),
        content: const Text(
            "تم بعث معلوماتك للادمن، عند الموافقة سوف يصلك رسالة على الإيميل"
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق النافذة
              // بعد الإغلاق نذهب لصفحة تسجيل الدخول
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PatientLoginPage()),
              );
            },
            child: const Text("موافق"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verify OTP"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), // اللون الأبيض
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Enter OTP sent to ${widget.email}"),
            SizedBox(height: 10),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "OTP",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text("Time remaining: $formattedTime"),
            SizedBox(height: 20),

            // زر التحقق دائمًا، لكن معطل أثناء العد أو أثناء التحميل
            ElevatedButton(
              onPressed: loading ? null : verifyOtp, // زر Verify دائمًا نشط إلا أثناء التحميل
              child: loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Verify"),
            ),

            TextButton(
              onPressed: (remainingSeconds == 0 && !loading) ? resendOtp : null, // زر Resend حسب العداد
              child: Text("Resend OTP"),
            ),

          ],
        ),
      ),
    );
  }
}
