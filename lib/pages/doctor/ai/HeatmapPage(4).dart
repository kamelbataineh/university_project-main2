import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

import '../../../core/config/app_font.dart';
import '../../auth/FullScreenImagePage.dart';
import 'AiFullScreenImagePage.dart';

class HeatmapPage extends StatefulWidget {
  final String imagePath;
  final String prediction;
  final List<double> probabilities;

  const HeatmapPage({
    super.key,
    required this.imagePath,
    required this.prediction,
    required this.probabilities,
  });

  @override
  State<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends State<HeatmapPage> {
  Uint8List? _overlayBytes;
  Uint8List? _heatmapBytes;
  String? _predLabelAr;
  List<double>? _probs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _probs = widget.probabilities;
    _predLabelAr = _translatePrediction(widget.prediction);
    _sendImageToServer(File(widget.imagePath));
  }

  String _translatePrediction(String pred) {
    switch (pred.toLowerCase()) {
      case "benign": return "Benign";
      case "malignant": return "Malignant";
      case "normal": return "Normal";
      default: return pred;
    }
  }

  Future<void> _sendImageToServer(File imageFile) async {
    setState(() => _loading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl1/ai/predict'));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var data = jsonDecode(respStr);

      setState(() {
        _overlayBytes = data['overlay'] != null ? base64Decode(data['overlay']) : null;
        _heatmapBytes = data['heatmap'] != null ? base64Decode(data['heatmap']) : null;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }




  Color getProbabilityColor(double value) {
    if (value >= 0.7) return Colors.red;       // نسبة عالية → أحمر
    if (value >= 0.4) return Colors.orange;    // متوسط → برتقالي
    return Colors.green;                        // منخفض → أخضر
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("Breast Cancer Heatmap", style: AppFont.regular(
          size: 18,
          weight: FontWeight.bold,
          color: Colors.white,
        ),),
        backgroundColor: Colors.indigo.shade400,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 300, // يمكنك تعديل الارتفاع
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200], // خلفية للحفاظ على المساحة الفارغة
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain, // كامل الصورة
                ),
              ),
            ),
            const SizedBox(height: 16),

            // النتيجة
            Text(
              "Prediction: $_predLabelAr",
               style: AppFont.regular(
              size: 20,
              weight: FontWeight.bold,
              color: Colors.indigo,
            ),),
            const SizedBox(height: 10),
// تحت الاحتمالات
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_probs != null) ...[
                  Text(
                    "Malignant: ${( _probs![1]*100).toStringAsFixed(1)}%",
                    style: AppFont.regular(
                      size: 16,
                      weight: FontWeight.bold,
                      color: getProbabilityColor(_probs![1]), // اللون حسب النسبة
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Benign: ${( _probs![0]*100).toStringAsFixed(1)}%",
                    style: AppFont.regular(
                      size: 16,
                      weight: FontWeight.bold,
                      color: getProbabilityColor(_probs![0]), // اللون حسب النسبة
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Normal: ${( _probs![2]*100).toStringAsFixed(1)}%",
                    style: AppFont.regular(
                      size: 16,
                      weight: FontWeight.bold,
                      color: getProbabilityColor(_probs![2]), // اللون حسب النسبة
                    ),
                  ),
                ] else
                  Text(
                    "Probabilities not available",
                    style: AppFont.regular(
                      size: 16,
                      weight: FontWeight.bold,
                      color: Colors.black, // لون افتراضي
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),

// Overlay
            if (_overlayBytes != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Overlay:", style: AppFont.regular(
                    size: 16,
                    weight: FontWeight.bold,
                    color: Colors.black,
                  ),),       const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiFullScreenImagePage(imageBytes: _overlayBytes!),
                        ),
                      );
                    },
                    child: Image.memory(_overlayBytes!, fit: BoxFit.cover),
                  ),
                ],
              ),

            const SizedBox(height: 20),

// Heatmap
            if (_heatmapBytes != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Heatmap Only:",
                    style: AppFont.regular(
                      size: 16,
                      weight: FontWeight.bold,
                      color: Colors.black,
                    ),),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiFullScreenImagePage(imageBytes: _heatmapBytes!),
                        ),
                      );
                    },
                    child: Image.memory(_heatmapBytes!, fit: BoxFit.cover),
                  ),
                ],
              ),
            const SizedBox(height: 70),

          ],
        ),
      ),
    );
  }
}
