import 'package:flutter/material.dart';

import '../password/pass_patient/PassPatientVerifyOtpPage.dart';

class EditEmailPage extends StatefulWidget {
  final String token;

  const EditEmailPage({Key? key, required this.token}) : super(key: key);

  @override
  _EditEmailPageState createState() => _EditEmailPageState();
}

class _EditEmailPageState extends State<EditEmailPage> {
  TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  get email => null;

  void _sendOtp() async {
    final email = _emailController.text.trim();
    if (!email.contains("@")) return;

    setState(() => _isLoading = true);

    // محاكاة طلب إرسال OTP
    await Future.delayed(Duration(seconds: 1));
    setState(() => _isLoading = false);

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //       builder: (_) => VerifyOtpPage(token: widget.token, )),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Email")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Enter your new email", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "New Email",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //       builder: (_) => VerifyOtpPage(token: widget.token, )),
                // );
              },
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Send OTP"),
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
