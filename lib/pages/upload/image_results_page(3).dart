import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

class ImageResultsPage extends StatefulWidget {
  final String imageUrl;
  final String imageName;
  final Function(String) onNavigate;
  final String prediction;
  final List probabilities;

  const ImageResultsPage({
    super.key,
    required this.imageUrl,
    required this.imageName,
    required this.onNavigate,
    required this.prediction,
    required this.probabilities,
  });

  @override
  State<ImageResultsPage> createState() => _ImageResultsPageState();
}

class _ImageResultsPageState extends State<ImageResultsPage> {
  bool _isAnalyzing = true;
  String _displayedText = "";
  final String _fullText = "Analyzing image for Pneumonia detection...";
  Timer? _typingTimer;
  @override
  void initState() {
    super.initState();
    _simulateTyping();
  }


  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }



  void _simulateTyping() {
    int index = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {  // 🟢 تحقق قبل setState
        timer.cancel();
        return;
      }
      if (index < _fullText.length) {
        setState(() {
          _displayedText += _fullText[index];
        });
        index++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;  // 🟢 تحقق قبل setState
          setState(() {
            _isAnalyzing = false;
          });
        });
      }
    });
  }

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
    List<String> classNames = ["benign", "malignant", "normal"];
    double maxProb = widget.probabilities.reduce((a, b) => a > b ? a : b);
    String severity = maxProb > 0.7
        ? "high"
        : maxProb > 0.4
        ? "medium"
        : "low";

    final Map<String, dynamic> results = {
      'condition': 'Pneumonia Detection',
      'confidence': (maxProb * 100),
      'severity': severity,
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Prediction
            Text(
              "Prediction: ${widget.prediction}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Probabilities
            ...List.generate(classNames.length, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${classNames[index]}: ${(widget.probabilities[index] * 100).toStringAsFixed(1)}%"),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: widget.probabilities[index],
                    minHeight: 10,
                    color: Colors.blueAccent,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),

            const SizedBox(height: 16),
            // Confidence
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Confidence: ${results['confidence'].toStringAsFixed(1)}%",
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

            // Severity
            Row(
              children: [
                severityIcon(results['severity']),
                const SizedBox(width: 8),
                Text(
                  "Severity: ${results['severity'].toUpperCase()}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: severityColor(results['severity']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Findings
            const Text(
              "Findings:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...results['recommendations'].map<Widget>((r) {
              return Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: Colors.green),
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
