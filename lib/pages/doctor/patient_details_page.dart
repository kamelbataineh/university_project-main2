import 'package:flutter/material.dart';
import 'package:university_project/pages/doctor/review_ai_result.dart';

class PatientDetailsPage extends StatelessWidget {
  final String name;
  final String age;
  final String lastVisit;

  PatientDetailsPage({
    Key? key,
    required this.name,
    required this.age,
    required this.lastVisit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Patient Details', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, color: Colors.blue, size: 50),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text('Age: $age', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Last Visit: $lastVisit', style: TextStyle(fontSize: 18)),
                SizedBox(height: 30),
                Divider(thickness: 1.5),
                SizedBox(height: 10),
                Text(
                  'Medical Notes:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'No notes available for this patient yet.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                Spacer(),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: Icon(Icons.analytics_outlined, color: Colors.white),
                    label: Text(
                      'View AI Analysis',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewAIResultPage(
                              patientName: name),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
