import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

class PdfViewerPage extends StatefulWidget {
  final String url;
  const PdfViewerPage({super.key, required this.url});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfControllerPinch? controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    try {
      final fullUrl = widget.url.startsWith("http") ? widget.url : "http://10.0.2.2:8000${widget.url}";
      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        controller = PdfControllerPinch(
          document: PdfDocument.openData(response.bodyBytes),
          initialPage: 1,
        );
      } else {
        throw Exception("خطأ في تحميل الملف");
      }
    } catch (e) {
      print("❌ PDF Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل تحميل PDF")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("عرض CV")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : controller == null
          ? const Center(child: Text("لا يمكن فتح الملف"))
          :PdfViewPinch(
        controller: controller!,
        scrollDirection: Axis.vertical, // تمرير رأسي
        onPageChanged: (page) {
          print("Current page: $page");
        },
      )




    );
  }
}
