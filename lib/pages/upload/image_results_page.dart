import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

class ImageResultsPage extends StatefulWidget {
  final String imageUrl;
  final String imageName;
  final Function(String) onNavigate;

  const ImageResultsPage({
    super.key,
    required this.imageUrl,
    required this.imageName,
    required this.onNavigate,
  });

  @override
  State<ImageResultsPage> createState() => _ImageResultsPageState();
}

class _ImageResultsPageState extends State<ImageResultsPage> {
  bool _isAnalyzing = true;
  String _displayedText = "";
  final String _fullText = "Analyzing image for Pneumonia detection...";

  @override
  void initState() {
    super.initState();
    _simulateTyping();
  }

  // محاكاة كتابة النص حرف حرف
  void _simulateTyping() {
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < _fullText.length) {
        setState(() {
          _displayedText += _fullText[index];
        });
        index++;
      } else {
        timer.cancel();
        // بعد الانتهاء نعرض النتائج بعد 0.5 ثانية
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _isAnalyzing = false;
          });
        });
      }
    });
  }

  final Map<String, dynamic> results = {
    'condition': 'Pneumonia Detection',
    'confidence': 87.5,
    'severity': 'medium',
    'findings': [
      'Consolidation detected in right lower lobe',
      'Increased opacity in affected area',
      'No signs of pleural effusion',
      'Cardiac silhouette within normal limits',
    ],
    'recommendations': [
      'Antibiotic therapy recommended',
      'Follow-up X-ray in 2 weeks',
      'Monitor oxygen saturation',
      'Consider sputum culture if symptoms persist',
    ],
  };

  Color severityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Icon severityIcon(String severity) {
    switch (severity) {
      case 'low':
        return const Icon(Icons.check_circle, color: Colors.white, size: 18);
      case 'medium':
      case 'high':
        return const Icon(Icons.warning_amber, color: Colors.white, size: 18);
      default:
        return const Icon(Icons.info, color: Colors.white, size: 18);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Analysis"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: _isAnalyzing
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _displayedText,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معاينة الصورة
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(widget.imageUrl),
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            // حالة التشخيص
            Text(
              results['condition'],
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // شريط الثقة
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Confidence: ${results['confidence']}%",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: results['confidence'] / 100,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.blueAccent,
                  minHeight: 10,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // شدة الحالة
            Row(
              children: [
                severityIcon(results['severity']),
                const SizedBox(width: 8),
                Text(
                  "Severity: ${results['severity'].toUpperCase()}",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: severityColor(results['severity'])),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Findings
            const Text(
              "Findings:",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...results['findings'].map<Widget>((f) {
              return Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.black54),
                  const SizedBox(width: 6),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                ],
              );
            }).toList(),
            const SizedBox(height: 16),
            // Recommendations
            const Text(
              "Recommendations:",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...results['recommendations'].map<Widget>((r) {
              return Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 18, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(child: Text(r, style: const TextStyle(fontSize: 14))),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
