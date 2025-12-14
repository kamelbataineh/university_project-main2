import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:university_project/pages/auth/PatientLoginPage.dart';
import '../../../core/config/app_config.dart';

class PatientResetPasswordPage extends StatefulWidget {
  final String email;
  final bool fromProfile;

  PatientResetPasswordPage({
    required this.email,
    this.fromProfile = false,
  });

  @override
  _PatientResetPasswordPageState createState() =>
      _PatientResetPasswordPageState();
}

class _PatientResetPasswordPageState extends State<PatientResetPasswordPage> {
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool loading = false;

  /// لعرض وإخفاء الباسورد
  bool _showNewPass = false;
  bool _showConfirmPass = false;

  /// لإظهار الشروط
  bool _showPasswordRequirements = false;

  // *************** شروط الباسورد ***************
  bool hasMinLength(String text) => text.length >= 8;
  bool hasNumber(String text) => RegExp(r'\d').hasMatch(text);
  bool hasSpecialChar(String text) =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(text);

  Widget _buildPasswordRequirement(String text, bool fulfilled) {
    return Row(
      children: [
        Icon(
          fulfilled ? Icons.check_circle : Icons.cancel,
          color: fulfilled ? Colors.green : Colors.red,
          size: 18,
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: fulfilled ? Colors.green : Colors.red,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // **************************************************

  Future<void> _resetPassword() async {
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.put(
        Uri.parse('$baseUrl1/patients/change-password-after-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'new_password': _newPassController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully')),
        );

        if (widget.fromProfile) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => PatientLoginPage()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['detail'] ?? 'Failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String pass = _newPassController.text;

    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======= NEW PASSWORD FIELD ========
            TextField(
              controller: _newPassController,
              obscureText: !_showNewPass,
              onChanged: (_) {
                setState(() {
                  _showPasswordRequirements = true;
                });
              },
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showNewPass = !_showNewPass;
                    });
                  },
                ),
              ),
            ),

            // ======= PASSWORD CONDITIONS ========
            if (_showPasswordRequirements) ...[
              SizedBox(height: 10),
              _buildPasswordRequirement(
                "At least 8 characters",
                hasMinLength(pass),
              ),
              _buildPasswordRequirement(
                "Contains letters and numbers",
                pass.contains(RegExp(r'[A-Za-z]')) && hasNumber(pass),
              ),
              _buildPasswordRequirement(
                "Contains at least one special character",
                hasSpecialChar(pass),
              ),

              SizedBox(height: 15),
            ],

            // ======= CONFIRM PASSWORD FIELD ========
            TextField(
              controller: _confirmPassController,
              obscureText: !_showConfirmPass,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPass
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirmPass = !_showConfirmPass;
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: loading ? null : _resetPassword,
                child: loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
