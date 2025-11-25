import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import 'VerifyOtpPage.dart'; // تأكد من تعريف baseUrl1 هنا

// ================== Forgot Password Page ==================
class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  void _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("saved_email") ?? "";
    setState(() {
      _emailController.text = savedEmail;
    });
  }
  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) return;

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl1/patients/send_otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      final resBodyStr = utf8.decode(response.bodyBytes);
      final data = jsonDecode(resBodyStr);

      if (response.statusCode == 200) {
        // الانتقال لصفحة التحقق من OTP مع تمرير البريد
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOtpPage(email: _emailController.text.trim()),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['detail'] ?? 'Error')),
        );
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
      appBar: AppBar(title: Text('Forgot Password')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _sendOtp,
              child: loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== Verify OTP Page ==================


// ================== Reset Password Page ==================


// ==
