import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../auth/patient_login_page.dart';

class PatientVerifyOtpPage extends StatefulWidget {
  final String email;
  const PatientVerifyOtpPage({required this.email, Key? key}) : super(key: key);

  @override
  State<PatientVerifyOtpPage> createState() => _PatientVerifyOtpPageState();
}

class _PatientVerifyOtpPageState extends State<PatientVerifyOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool loading = false;
  int remainingSeconds = 120; // 2 دقيقة
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
      remainingSeconds = 120;
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
    setState(() => loading = true);
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}patients/confirm_registration?email=${widget.email}&otp=${_otpController.text.trim()}"),
      );

      final resBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration confirmed ✅")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PatientLoginPage()),
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

  Future<void> resendOtp() async {
    setState(() => loading = true);
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}patients/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email}),
      );

      final resBody = jsonDecode(utf8.decode(response.bodyBytes));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resBody["detail"] ?? "OTP sent again ✅")),
      );

      startTimer(); // إعادة تشغيل العداد بعد الإرسال
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to resend OTP: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
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
