import 'package:flutter/material.dart';
import 'package:university_project/pages/doctor/patient_details_page.dart';
import 'package:university_project/pages/doctor/review_ai_result.dart';

class PatientsListPage extends StatelessWidget {
  PatientsListPage({Key? key}) : super(key: key);

  final List<Map<String, String>> _patients = [
    {'name': 'Sara Ahmad', 'age': '29', 'lastVisit': '2025-09-25'},
    {'name': 'Khaled Hassan', 'age': '42', 'lastVisit': '2025-09-18'},
    {'name': 'Mohammad Ali', 'age': '36', 'lastVisit': '2025-09-10'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Patients List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          final patient = _patients[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, color: Colors.blue),
              ),
              title: Text(patient['name']!,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Age: ${patient['age']}\nLast Visit: ${patient['lastVisit']}'),
              isThreeLine: true,
              trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetailsPage(
                          name: patient['name']!,
                          age: patient['age']!,
                          lastVisit: patient['lastVisit']!,
                        ),
                      ),
                    );
                  }),
            ),
          );
        },
      ),
    );
  }
}
