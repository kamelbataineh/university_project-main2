import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

class CreateAdminPage extends StatefulWidget {
  const CreateAdminPage({Key? key}) : super(key: key);

  @override
  State<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdminPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool loading = false;

  Future<void> createAdmin() async {
    if (_email.text.isEmpty || _password.text.isEmpty) return;
    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse(adminCreate),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email.text,
          "password": _password.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Admin account created successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
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
      appBar: AppBar(title: const Text("Create Admin")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: loading ? null : createAdmin,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Admin"))
          ],
        ),
      ),
    );
  }
}
