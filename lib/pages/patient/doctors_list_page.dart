import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../components/PatientDoctorProfile_OR_ChatDoctorProfile.dart';
import '../components/ChatPatientProfile.dart';

const baseUrl = "http://10.0.2.2:8000/";

class DoctorsListPage extends StatefulWidget {
  final String token;
  final String userId;

  const DoctorsListPage({Key? key, required this.token, required this.userId}) : super(key: key);

  @override
  State<DoctorsListPage> createState() => _DoctorsListPageState();
}

class _DoctorsListPageState extends State<DoctorsListPage> {
  List doctors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await http.get(
        Uri.parse("${baseUrl}patients/doctors"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        setState(() {
          doctors = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load doctors");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load doctors")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:

       isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          final fullName =
          "${doctor['first_name'] ?? ''} ${doctor['last_name'] ?? ''}".trim();

          // استخراج ID بطريقة آمنة
          String doctorId;
          if (doctor["_id"] is Map && doctor["_id"]["\$oid"] != null) {
            doctorId = doctor["_id"]["\$oid"];
          } else {
            doctorId = doctor["_id"].toString();
          }

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: doctor['profile_image_url'] != null
                    ? NetworkImage("$baseUrl${doctor['profile_image_url']}")
                    : null,
                child: doctor['profile_image_url'] == null
                    ? const Icon(Icons.person_outline, color: Colors.pink)
                    : null,
                backgroundColor: Colors.pink.shade100,
              ),
              title: Text(fullName.isNotEmpty ? fullName : "Doctor"),
              subtitle: Text(doctor['specialization'] ?? "No specialization"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientdoctorprofileOrChatdoctorprofile(
                      doctorId: doctorId,
                      userId: widget.userId,
                      token: widget.token,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
