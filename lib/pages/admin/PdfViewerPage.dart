import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../../core/config/app_config.dart';

class PdfViewerPage extends StatefulWidget {
  final String url;
  const PdfViewerPage({super.key, required this.url});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfControllerPinch? pdfController;
  bool loading = true;
  bool isPdf = false;

  @override
  void initState() {
    super.initState();
    loadFile();
  }

  Future<void> loadFile() async {
    try {
      final fullUrl = widget.url.startsWith("http")
          ? widget.url
          : "$baseUrl1${widget.url}";

      // تحقق من الامتداد لتحديد نوع الملف
      final ext = fullUrl.split('.').last.toLowerCase();
      isPdf = ext == "pdf";

      if (isPdf) {
        final response = await http.get(Uri.parse(fullUrl));
        if (response.statusCode == 200) {
          pdfController = PdfControllerPinch(
            document: PdfDocument.openData(response.bodyBytes),
            initialPage: 1,
          );
        } else {
          throw Exception("خطأ في تحميل PDF");
        }
      }
      // إذا كانت صورة، لا حاجة لتحميل مسبق (Image.network يستخدم URL مباشرة)
    } catch (e) {
      print("❌ Error loading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل تحميل الملف")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
          backgroundColor: Colors.white,
          title: const Text("عرض الملف",style: TextStyle(color: Colors.black),)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : isPdf
          ? (pdfController == null
          ? const Center(child: Text("لا يمكن فتح الملف"))
          : PdfViewPinch(
        controller: pdfController!,
        scrollDirection: Axis.vertical,
        onPageChanged: (page) {
          print("Current page: $page");
        },
      ))
          : Center(
        child: Image.network(
          widget.url.startsWith("http")
              ? widget.url
              : "$baseUrl1${widget.url}",
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text("فشل تحميل الصورة");
          },
        ),
      ),
    );
  }
}
