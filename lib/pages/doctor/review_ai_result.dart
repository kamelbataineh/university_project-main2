import 'package:flutter/material.dart';
class ReviewAIResultPage extends StatefulWidget {
  final String patientName;

  const ReviewAIResultPage({Key? key, required this.patientName}) : super(key: key);

  @override
  State<ReviewAIResultPage> createState() => _ReviewAIResultPageState();
}

class _ReviewAIResultPageState extends State<ReviewAIResultPage> {

  final List<Map<String, String>> _allResults = [
    {
      'patient': 'Sara Ahmad',
      'aiResult': 'Possible tumor detected (85% confidence)',
      'status': 'Pending Review',
    },
    {
      'patient': 'Khaled Hassan',
      'aiResult': 'No abnormality detected',
      'status': 'Reviewed',
    },
  ];

  late List<Map<String, String>> _aiResults;

  @override
  void initState() {
    super.initState();
    // فلترة النتائج حسب اسم المريض
    _aiResults = _allResults
        .where((res) => res['patient'] == widget.patientName)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('AI Analysis for ${widget.patientName}'),
        centerTitle: true,
      ),
      body: _aiResults.isEmpty
          ? Center(child: Text('No AI results for this patient yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _aiResults.length,
        itemBuilder: (context, index) {
          final result = _aiResults[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Result: ${result['aiResult']}'),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${result['status']}',
                    style: TextStyle(
                        color: result['status'] == 'Reviewed'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _aiResults[index]['status'] = 'Reviewed';
                          });
                        },
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        label: const Text('Mark Reviewed'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
