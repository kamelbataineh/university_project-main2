import 'package:flutter/material.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({Key? key}) : super(key: key);

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final List<Map<String, String>> _results = [
    {
      'title': 'Blood Test',
      'date': '2025-10-01',
      'status': 'Normal',
      'doctor': 'Dr. Ahmed Khalid'
    },
    {
      'title': 'MRI Scan',
      'date': '2025-09-25',
      'status': 'Further review needed',
      'doctor': 'Dr. Lina Al-Majali'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title:  Text(
          'Medical Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _results.isEmpty
            ? const Center(
          child: Text(
            'No results available yet.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        )
            : ListView.builder(
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final result = _results[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.analytics_outlined,
                      color: Colors.blue.shade700),
                ),
                title: Text(
                  result['title']!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Doctor: ${result['doctor']}'),
                    Text('Date: ${result['date']}'),
                    Text(
                      'Status: ${result['status']}',
                      style: TextStyle(
                        color: result['status'] == 'Normal'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.picture_as_pdf_outlined,
                      color: Colors.blue),
                  onPressed: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
