import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/chat_page.dart';
class DoctorProfilePage extends StatelessWidget {
  final Map doctor;
  final String userId; // ID المستخدم الحالي
  final String token;  // توكن الدخول

  const DoctorProfilePage({
    Key? key,
    required this.doctor,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullName = "${doctor["first_name"]} ${doctor["last_name"]}".trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 6,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding:  EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.pink.shade400,
                    child: Text(
                      fullName[0],
                      style:  TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                 SizedBox(height: 20),
                Text("Dr. $fullName",
                    style:
                     TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 SizedBox(height: 10),
                Text("Email: ${doctor["email"]}",
                    style:  TextStyle(fontSize: 16)),
                 SizedBox(height: 10),
                Text("Phone: ${doctor["phone_number"]}",
                    style:  TextStyle(fontSize: 16)),
                // // const SizedBox(height: 10),
                // // Text("Approved: ${doctor["is_approved"] ? "Yes" : "No"}",
                //     style: const TextStyle(fontSize: 16)),
                 SizedBox(height: 10),
              //   Text("CV File:",
              //       style:
              //       const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              //   const SizedBox(height: 5),
              //   Text(
              //     doctor["cv_url"] ?? "Not uploaded",
              //     style: const TextStyle(fontSize: 14, color: Colors.blue),
              //   ),
              ],
            ),
          ),
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
                userId: userId,
                otherId: doctor["id"],
                token: token,
              ),
            ),
          );
        },
      ),
    );
  }
}
