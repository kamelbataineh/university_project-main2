import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'PatientResetPasswordPage.dart';

class PassPatientVerifyOtpPage extends StatefulWidget {
  final String email;
  final bool fromProfile;

  PassPatientVerifyOtpPage({
    required this.email,
    this.fromProfile = false,
  });

  @override
  _PassPatientVerifyOtpPageState createState() =>
      _PassPatientVerifyOtpPageState();
}

class _PassPatientVerifyOtpPageState extends State<PassPatientVerifyOtpPage> {
  final _otpController = TextEditingController();
  bool loading = false;
  bool canResend = true;
  int countdown = 60;
  Timer? _timer;

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // إرسال OTP مباشرة أول ما يدخل المستخدم الصفحة
    Future.microtask(() {
      _resendOtp();
    });
  }

  void startCountdown() {
    setState(() {
      canResend = false;
      countdown = 60;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (countdown > 0) {
          countdown--;
        } else {
          canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) return;

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl1/patients/verify_otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': _otpController.text.trim(),
        }),
      );

      final resBodyStr = utf8.decode(response.bodyBytes);
      final data = jsonDecode(resBodyStr);

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PatientResetPasswordPage(
              email: widget.email,
              fromProfile: widget.fromProfile, // ⬅️ important
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['detail'] ?? 'OTP failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Connection error')));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!canResend) return;

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl1/patients/send_otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP resent to ${widget.email}')),
        );
        startCountdown(); // ⬅️ بدء العد بعد الإرسال
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['detail'] ?? 'Failed to resend OTP')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Connection error')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify OTP')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _otpController,
              decoration: InputDecoration(labelText: 'Enter OTP'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _verifyOtp,
              child: loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Verify'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: canResend ? _resendOtp : null,
              child: canResend
                  ? Text('Resend OTP')
                  : Text('Resend in $countdown s'),
            ),
          ],
        ),
      ),
    );
  }
}
