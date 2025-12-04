import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // لعرض PDF
import 'package:url_launcher/url_launcher.dart'; // لفتح روابط الصور أو PDF

class DoctorProfilePage extends StatelessWidget {
  final Map doctor;
  final Function()? onApprove;

  const DoctorProfilePage({super.key, required this.doctor, this.onApprove});

  @override
  Widget build(BuildContext context) {
    final cvUrl = doctor['cv_url'];

    return Scaffold(
      appBar: AppBar(title: Text("${doctor['first_name']} ${doctor['last_name']}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${doctor['email']}"),
            Text("Phone: ${doctor['phone_number'] ?? '-'}"),
            Text("Approved: ${doctor['is_approved']}"),
            const SizedBox(height: 20),
            if (cvUrl != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("عرض السيرة الذاتية"),
                onPressed: () async {
                  if (cvUrl.endsWith(".pdf")) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PDFViewPage(pdfPath: cvUrl)));
                  } else {
                    // فتح الصور في المتصفح
                    if (await canLaunch(cvUrl)) {
                      await launch(cvUrl);
                    }
                  }
                },
              ),
            const Spacer(),
            if (onApprove != null)
              ElevatedButton(
                onPressed: onApprove,
                child: const Text("موافق"),
              ),
          ],
        ),
      ),
    );
  }
}

// صفحة عرض PDF
class PDFViewPage extends StatelessWidget {
  final String pdfPath;

  const PDFViewPage({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("عرض CV")),
      body: PDFView(
        filePath: pdfPath,
      ),
    );
  }
}
