import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'doctor_profile_page.dart';

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
    final url = Uri.parse(getAllDoctorsUrl);

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      // 🖨️ للطباعة في console
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");


      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        setState(() {
          doctors = decoded["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);

        print("Error fetching doctors: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching doctors: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      print("Exception occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception occurred: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(



      body: isLoading
          ?  Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          final fullName =
          "${doctor["first_name"]} ${doctor["last_name"]}".trim();

          return Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.shade100.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // صورة افتراضية للدكتور
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.pink.shade300,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0] : "?",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(width: 16),

                // معلومات الدكتور
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor["email"] ?? "",
                        style: TextStyle(
                            color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Phone: ${doctor["phone_number"] ?? "N/A"}",
                        style: TextStyle(
                            color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                // زر فتح البروفايل
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      color: Colors.pink),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorProfilePage(
                          doctor: doctor,
                          userId: widget.userId,  // ✅ استخدم هنا widget.userId
                          token: widget.token,    // ✅ صحيح
                        ),
                      ),

                );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

