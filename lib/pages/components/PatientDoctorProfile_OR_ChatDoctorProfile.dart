import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:university_project/pages/patient/BookAppointmentPage_doctor.dart';
import '../auth/FullScreenImagePage.dart';
import 'chat_page.dart';

const baseUrl = "http://10.0.2.2:8000";

class PatientdoctorprofileOrChatdoctorprofile extends StatefulWidget {
  final String doctorId;
  final String userId;
  final String token;

  const PatientdoctorprofileOrChatdoctorprofile({
    Key? key,
    required this.doctorId,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  State<PatientdoctorprofileOrChatdoctorprofile> createState() => _ChatDoctorProfileState();
}

class _ChatDoctorProfileState extends State<PatientdoctorprofileOrChatdoctorprofile> {
  Map<String, dynamic>? doctor;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctor();
  }

  Future<void> fetchDoctor() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/patients/doctors/${widget.doctorId}"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        setState(() {
          doctor = jsonDecode(response.body);
          loading = false;
        });
      } else {
        throw Exception('Failed to load doctor');
      }
    } catch (e) {
      print(e);
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading doctor data')),
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

    if (doctor == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Doctor Profile"),
          backgroundColor: Colors.pink,
          centerTitle: true,
        ),
        body: const Center(child: Text("Doctor not found")),
      );
    }

    final fullName = "${doctor!["first_name"] ?? ''} ${doctor!["last_name"] ?? ''}".trim();

    // استخراج ID بطريقة آمنة
    String doctorId;
    if (doctor!["_id"] is Map && doctor!["_id"]["\$oid"] != null) {
      doctorId = doctor!["_id"]["\$oid"];
    } else {
      doctorId = doctor!["_id"].toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName.isNotEmpty ? fullName : "Doctor Profile"),
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
              child: doctor!['profile_image_url'] != null
                  ? GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(
                        imageUrl: "$baseUrl/${doctor!['profile_image_url']}",
                      ),
                    ),
                  );
                },
                child: ClipOval(
                  child: Image.network(
                    "$baseUrl/${doctor!['profile_image_url']}",
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person_outline, size: 70, color: Colors.pink);
                    },
                  ),
                ),
              )
                  : const Icon(Icons.person_outline, size: 70, color: Colors.pink),
            ),


            const SizedBox(height: 20),
            Text(
              "Dr. $fullName",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              doctor!['specialization'] ?? 'No specialization',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),

            buildInfoCard(Icons.email_outlined, 'Email', doctor!['email']),
            buildInfoCard(Icons.phone_android_outlined, 'Phone', doctor!['phone_number']),
            buildInfoCard(Icons.schedule, 'Experience',
                doctor!['years_of_experience'] != null ? "${doctor!['years_of_experience']} years" : null),
            buildInfoCard(Icons.location_on_outlined, 'Location', doctor!['location']),
            buildInfoCard(Icons.male, 'Gender', doctor!['gender']),
            buildInfoCard(Icons.info_outline, 'Bio', doctor!['bio']),
            // buildInfoCard(Icons.file_present, 'CV', doctor!['cv_url'] != null ? doctor!['cv_url'] : null),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointmentPageDoctor(
                      token: widget.token,
                      doctorId: doctorId,
                      doctorName: fullName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text("Book Appointment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          ],

        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.chat),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                name: fullName,
                userId: widget.userId,
                otherId: doctorId,
                token: widget.token,
              ),
            ),
          );
        },
      ),
    );
  }
}
