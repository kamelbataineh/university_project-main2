import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'EditEmailPage.dart';

class VerifyPasswordPage extends StatefulWidget {
  final String token;

  const VerifyPasswordPage({Key? key, required this.token}) : super(key: key);

  @override
  _VerifyPasswordPageState createState() => _VerifyPasswordPageState();
}

class _VerifyPasswordPageState extends State<VerifyPasswordPage> {
  TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _verifyPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() => _isLoading = true);

    // هنا تحط request للفاست API للتحقق من كلمة السر
    await Future.delayed(Duration(seconds: 1)); // محاكاة الطلب
    bool success = password == "123456"; // مثال مؤقت

    setState(() => _isLoading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EditEmailPage(token: widget.token)),
    );
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EditEmailPage(token: widget.token)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Incorrect password"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify Password")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Enter your password to continue",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditEmailPage(token: widget.token)),
                );
              },
              // _verifyPassword,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Verify"),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}
