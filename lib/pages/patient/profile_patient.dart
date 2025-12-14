import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:university_project/pages/auth/FullScreenImagePage.dart';
import 'package:university_project/pages/auth/PatientLoginPage.dart';
import 'package:university_project/pages/patient/EditPatientProfilePage.dart';
import 'dart:convert';
import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';

class ProfilePatientPage extends StatefulWidget {
  final String token;
  const ProfilePatientPage({Key? key, required this.token}) : super(key: key);

  @override
  _ProfilePatientPageState createState() => _ProfilePatientPageState();
}
const baseUrl = "http://10.0.2.2:8000/";

class _ProfilePatientPageState extends State<ProfilePatientPage> {
  Map<String, dynamic>? patientData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatientProfile();
  }

  Future<void> fetchPatientProfile() async {
    final url = Uri.parse(patientMe);
    final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});

    if (response.statusCode == 200) {
      setState(() {
        patientData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print('Error: ${response.body}');
    }
  }

  Widget profileCard({required String title, required String value, IconData? icon, required VoidCallback onEdit}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF5F5F5),
        boxShadow: const [
          BoxShadow(color: Colors.grey, offset: Offset(3, 3), blurRadius: 6),
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: icon != null
            ? Icon(icon, color: AppTheme.patientIcon)
            : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : patientData == null
          ? const Center(child: Text('Failed to load profile'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImagePage(
                            imageUrl: "$baseUrl${patientData!['profile_image_url']}",
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: patientData!['profile_image_url'] != null
                          ? NetworkImage("${baseUrl}${patientData!['profile_image_url']}?t=${DateTime.now().millisecondsSinceEpoch}")
                          : null,

                      child: (patientData!['profile_image_url'] == null ||
                          patientData!['profile_image_url'].isEmpty)
                          ? const Icon(Icons.person_outline, size: 70, color: Colors.blue)
                          : null,
                    ),
                  )
,
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EditPatientProfilePage(patientData: patientData!, token:widget.token)
                            ));
                      },
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 18, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // الاسم
              Text(
                "${patientData!['first_name']} ${patientData!['last_name']}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // الكروت
              profileCard(
                title: "Email",
                value: patientData!['email'],
                icon: Icons.mail,
                onEdit: () {}, // هنا رابط تعديل
              ),
              profileCard(
                title: "Phone",
                value: patientData!['phone_number'],
                icon: Icons.phone,
                onEdit: () {},
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      // عرض نافذة التأكيد
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );

                      // إذا ضغط المستخدم نعم
                      if (shouldLogout ?? false) {
                        final response = await http.post(
                          Uri.parse('$baseUrl1/patients/logout'),
                          headers: {
                            'Authorization': 'Bearer ${widget.token}',
                          },
                        );

                        if (response.statusCode == 200) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientLoginPage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logout failed. Please try again.')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.patientAppbar,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPatientProfilePage(patientData: patientData!, token: widget.token),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.patientAppbar,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
