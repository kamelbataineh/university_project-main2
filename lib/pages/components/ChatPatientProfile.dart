import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/FullScreenImagePage.dart';
import 'chat_page.dart';

const baseUrl = "http://10.0.2.2:8000";

class ChatPatientProfile extends StatefulWidget {
  final String patientId;   // مريض
  final String userId;      // الدكتور الحالي
  final String token;

  const ChatPatientProfile({
    Key? key,
    required this.patientId,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  State<ChatPatientProfile> createState() => _ChatPatientProfileState();
}

class _ChatPatientProfileState extends State<ChatPatientProfile> {
  Map<String, dynamic>? patient;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPatient();
  }

  Future<void> fetchPatient() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/doctors/patients/${widget.patientId}"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        setState(() {
          patient = jsonDecode(response.body);
          loading = false;
        });
      } else {
        throw Exception('Failed to load patient');
      }
    } catch (e) {
      print(e);
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading patient data')),
      );
    }
  }

  Widget buildInfoCard(IconData icon, String title, String? value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.pink),
        title: Text(title),
        subtitle: Text(value != null && value.isNotEmpty ? value : 'Not added'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Loading..."),
          backgroundColor: Colors.pink,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Patient Profile"),
          backgroundColor: Colors.pink,
          centerTitle: true,
        ),
        body: const Center(child: Text("Patient not found")),
      );
    }

    final fullName =
    "${patient!["first_name"] ?? ''} ${patient!["last_name"] ?? ''}".trim();

    String patientId;
    if (patient!["_id"] is Map && patient!["_id"]["\$oid"] != null) {
      patientId = patient!["_id"]["\$oid"];
    } else {
      patientId = patient!["_id"].toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName.isNotEmpty ? fullName : "Patient Profile"),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.pink.shade100,
              child: patient!['profile_image_url'] != null
                  ? GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(
                        imageUrl:
                        "$baseUrl/${patient!['profile_image_url']}",
                      ),
                    ),
                  );
                },
                child: ClipOval(
                  child: Image.network(
                    "$baseUrl/${patient!['profile_image_url']}",
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person_outline,
                          size: 70, color: Colors.pink);
                    },
                  ),
                ),
              )
                  : const Icon(Icons.person_outline,
                  size: 70, color: Colors.pink),
            ),

            const SizedBox(height: 20),
            Text(
              fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            // معلومات المريض
            buildInfoCard(Icons.email_outlined, 'Email', patient!['email']),
            buildInfoCard(
                Icons.phone_android_outlined, 'Phone', patient!['phone_number']),
            buildInfoCard(Icons.male, 'Gender', patient!['gender']),
            buildInfoCard(Icons.cake, 'Age', "${patient!['age'] ?? ''}"),
            buildInfoCard(Icons.info_outline, 'Bio', patient!['bio']),
          ],
        ),
      ),
    );}}