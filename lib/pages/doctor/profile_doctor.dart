import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:university_project/pages/doctor/EditDoctorProfilePage.dart';
import 'dart:convert';

import '../../core/config/app_config.dart';

class ProfileDoctorPage extends StatefulWidget {
  final String token;

  const ProfileDoctorPage({Key? key, required this.token}) : super(key: key);

  @override
  _ProfileDoctorPageState createState() => _ProfileDoctorPageState();
}

class _ProfileDoctorPageState extends State<ProfileDoctorPage> {
  Map<String, dynamic>? doctorData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctorProfile();
  }

  Future<void> fetchDoctorProfile() async {
    final url = Uri.parse(doctorMe); 
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}', 
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        doctorData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      print('Error: ${response.body}');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // appBar: AppBar(
      //   backgroundColor: Colors.blue,
      //   title:  Text(
      //     'Doctor Profile',
      //     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      //   ),
      //   centerTitle: true,
      // ),
      body: isLoading
          ?  Center(child: CircularProgressIndicator())
          : doctorData == null
          ?  Center(child: Text('Failed to load profile '))
          : SingleChildScrollView(
        child: Padding(
          padding:  EdgeInsets.all(10.0),
          child: Column(
            children: [
               SizedBox(height: 30),
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.blue.shade100,
                child:  Icon(
                  Icons.person_outline,
                  size: 70,
                  color: Colors.blue,
                ),
              ),
               SizedBox(height: 20),
              Text(
                "Dr. ${doctorData!['first_name']} ${doctorData!['last_name']}",
                style:  TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                doctorData!['specialization'] ?? 'No specialization',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
               SizedBox(height: 30),
              buildInfoCard(Icons.email_outlined, 'Email',
                  doctorData!['email'] ?? 'N/A'),
               SizedBox(height: 10),
              buildInfoCard(Icons.local_hospital_outlined, 'Department',
                  doctorData!['department'] ?? 'N/A'),
               SizedBox(height: 10),
              buildInfoCard(Icons.phone_android_outlined, 'Phone',
                  doctorData!['phone_number'] ?? 'N/A'),
               SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>EditDoctorProfilePage(doctorData: doctorData!)
                        ),
                      );                   },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding:  EdgeInsets.symmetric(
                          horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon:  Icon(Icons.edit_outlined,
                        color: Colors.white),
                    label:  Text(
                      'Edit Profile',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding:  EdgeInsets.symmetric(
                          horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon:  Icon(Icons.logout, color: Colors.white),
                    label:  Text(
                      'Logout',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
               SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
