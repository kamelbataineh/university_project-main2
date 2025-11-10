import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _email =
  TextEditingController(text: "admin@system.com");
  final TextEditingController _password =
  TextEditingController(text: "Admin1234");
  bool loading = false;

  Future<void> loginAdmin() async {
    setState(() => loading = true);
    try {
      final response = await http.post(
          Uri.parse(adminLogin),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": _email.text,
            "password": _password.text,
          }));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged in as Admin!")),
        );
        // تنقل لصفحة الأدمن الرئيسية
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade500]),
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.shade200.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(8, 8)),
              BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 12,
                  offset: const Offset(-8, -8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings,
                  size: 50, color: Colors.white),
              const SizedBox(height: 16),
              const Text("Admin Login",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                    labelText: "Email", filled: true, fillColor: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Password", filled: true, fillColor: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: loading ? null : loginAdmin,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login"))
            ],
          ),
        ),
      ),
    );
  }
}
