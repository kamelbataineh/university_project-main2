import 'package:flutter/material.dart';
import 'package:university_project/pages/doctor/records/update_record_page.dart';
import '../../../services/medical_record_service.dart';
import 'add_record_page.dart';

class MedicalRecordsPage extends StatefulWidget {
  final String token;
  final String patientId;

  const MedicalRecordsPage({
    super.key,
    required this.token,
    required this.patientId,
  });

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  late MedicalRecordService _service;
  List records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _service = MedicalRecordService(
      baseUrl: "http://10.0.2.2:8000",
      token: widget.token,
    );
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await _service.getRecords(widget.patientId);
      setState(() {
        records = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medical Records")),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (_) => AddRecordPage(
      //         token: widget.token,
      //         patientId: widget.patientId,
      //       ),
      //     ),
      //   ).then((_) => loadData()),
      //   child: const Icon(Icons.add),
      // ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (_, index) {
          final record = records[index];

          return Card(
            child: ListTile(
              title: Text(record["diagnosis"]),
              subtitle: Text(record["notes"]),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await _service.deleteRecord(
                    widget.patientId,
                    record["_id"],
                  );
                  loadData();
                },
              ),
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) => UpdateRecordPage(
            //         token: widget.token,
            //         patientId: widget.patientId,
            //         recordId: record["_id"],
            //         oldNotes: record["notes"],
            //       ),
            //     ),
            //   ).then((_) => loadData()),
            ),
          );
        },
      ),
    );
  }
}
