import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/config/app_font.dart';
import '../auth/EditDoctorProfilePage.dart';
import '../auth/LoginDoctorPage.dart';

const baseUrl = "http://10.0.2.2:8000/";

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
    final url = Uri.parse("${baseUrl}doctors/me");
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
      print('Error fetching profile: ${response.body}');
      setState(() {
        isLoading = false;
      });
    }
  }




  Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/doctors/logout"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to logout")),
      );
    }
  }





  Widget buildOptionalField(
      String title, String? value, IconData icon, VoidCallback onEdit) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo.shade400),
        title: Text(title),
        subtitle: value != null && value.isNotEmpty
            ? Text(value)
            : Text('Not added', style: TextStyle(color: Colors.grey)),
        // تعديل هنا:
        trailing: (value == null || value.isEmpty)
            ? IconButton(
          icon: Icon(Icons.add, color: Colors.indigo.shade400),
          onPressed: onEdit,
        )
            : null, // إذا موجود القيمة، لا يظهر أي زر
      ),
    );
  }


  Widget buildInfoCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo.shade400),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : doctorData == null
          ? Center(child: Text('Failed to load profile'))
          : SingleChildScrollView(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            SizedBox(height: 30),
            Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: doctorData!['profile_image_url'] != null
                      ? NetworkImage("${baseUrl}${doctorData!['profile_image_url']}")
                      : null,
                  child: doctorData!['profile_image_url'] == null
                      ? Icon(Icons.person_outline, size: 70, color: Colors.indigo.shade400)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => EditDoctorProfilePage(
                                doctorData: doctorData!,
                                token: widget.token,
                              )));
                    },
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 18, color: Colors.indigo.shade400),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Dr. ${doctorData!['first_name']} ${doctorData!['last_name']}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              doctorData!['specialization'] ?? 'No specialization',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            SizedBox(height: 20),

            // الحقول الاختيارية

            buildInfoCard(Icons.email_outlined, 'Email',
                doctorData!['email'] ?? 'N/A'),
            SizedBox(height: 10),
            buildInfoCard(Icons.phone_android_outlined, 'Phone',
                doctorData!['phone_number'] ?? 'N/A'),
            SizedBox(height: 20),
            Divider(color: Colors.grey.shade400, thickness: 3), // ← الخط هنا
            SizedBox(height: 20),
            buildOptionalField('Bio', doctorData!['bio'], Icons.info_outline,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditDoctorProfilePage(
                        doctorData: doctorData!,
                        token: widget.token,
                      ),
                    ),
                  );
                }),
            buildOptionalField('Location', doctorData!['location'],
                Icons.location_on_outlined, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditDoctorProfilePage(
                        doctorData: doctorData!,
                        token: widget.token,
                      ),
                    ),
                  );
                }),
            buildOptionalField('Gender', doctorData!['gender'], Icons.male, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditDoctorProfilePage(
                    doctorData: doctorData!,
                    token: widget.token,
                  ),
                ),
              );
            }),
            buildOptionalField(
                'Specialization', doctorData!['specialization'], Icons.local_hospital_outlined,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditDoctorProfilePage(
                        doctorData: doctorData!,
                        token: widget.token,
                      ),
                    ),
                  );
                }),
            buildOptionalField(
                'Experience',
                doctorData!['years_of_experience'] != null
                    ? "${doctorData!['years_of_experience']} years"
                    : null,
                Icons.schedule, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditDoctorProfilePage(
                    doctorData: doctorData!,
                    token: widget.token,
                  ),
                ),
              );
            }),


            SizedBox(height: 30),

            // أزرار Edit/Logout بشكل أكثر أناقة ومرتب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditDoctorProfilePage(
                          doctorData: doctorData!,
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                  label: Text(
                    'Edit Profile',
                    style: AppFont.regular(
                      size: 13, // حجم الخط متناسق مع باقي الأزرار الصغيرة
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14), // حواف دائرية متناسقة
                    ),
                    elevation: 3,
                    shadowColor: Colors.indigo.shade200,
                    minimumSize: const Size(120, 38), // نفس حجم الأزرار الصغيرة
                  ),
                ),


                ElevatedButton.icon(
                  onPressed: () {
                    // إظهار نافذة التأكيد
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // إغلاق النافذة بدون Logout
                            },
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () async {
                              await logout(widget.token);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginDoctorPage()),
                              );
                            },
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                  label: Text(
                    'Logout',
                    style: AppFont.regular(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor: Colors.white,
                    minimumSize: const Size(120, 38), // نفس حجم الأزرار الصغيرة
                  ),
                ),

              ],
            ),
            SizedBox(height: 30),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
