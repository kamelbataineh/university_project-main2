import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class HeatmapPage extends StatefulWidget {
  final String imagePath; // الصورة من الصفحة السابقة
  final String prediction; // النتيجة الأصلية (english)
  final List<double> probabilities; // الاحتمالات الأصلية

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
  String? _predLabelAr; // ← النتيجة بالعربي
  List<double>? _probs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _probs = widget.probabilities;
    _predLabelAr = _translatePrediction(widget.prediction);

    // رفع الصورة إلى السيرفر للحصول على Overlay و Heatmap
    _sendImageToServer(File(widget.imagePath));
  }

  // ترجمة النتيجة من الإنجليزي → عربي
  String _translatePrediction(String pred) {
    switch (pred.toLowerCase()) {
      case "benign":
        return "benign";
      case "malignant":
        return "malignant";
      case "normal":
        return "normal";
      default:
        return pred;
    }
  }

  Future<void> _sendImageToServer(File imageFile) async {
    setState(() {
      _loading = true;
    });

    try {
      var request =
      http.MultipartRequest('POST', Uri.parse('$baseUrl1/ai/predict'));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var data = jsonDecode(respStr);

      setState(() {
        _overlayBytes = data['overlay'] != null
            ? base64Decode(data['overlay'])
            : null;
        _heatmapBytes = data['heatmap'] != null
            ? base64Decode(data['heatmap'])
            : null;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Breast Cancer Heatmap"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Prediction: $_predLabelAr",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // بدلاً من السطر القديم
// "Probabilities: ${_probs?.map((e) => e.toStringAsFixed(2)).join(', ')}",

// نستخدم هذا:
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    _probs != null
                        ?"malignant: ${( _probs![1] * 100).toStringAsFixed(1)}%  "
                        "benign: ${( _probs![0] * 100).toStringAsFixed(1)}%  "
                        "normal: ${( _probs![2] * 100).toStringAsFixed(1)}%"
                        : "Probabilities not available",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _overlayBytes != null
                  ? Column(
                children: [
                  const Text("Overlay:"),
                  Image.memory(_overlayBytes!),
                ],
              )
                  : Container(),
              const SizedBox(height: 20),
              _heatmapBytes != null
                  ? Column(
                children: [
                  const Text("Heatmap Only:"),
                  Image.memory(_heatmapBytes!),
                ],
              )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}




// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:http/http.dart' as http;
//
// import '../../../core/config/app_config.dart';
//
// class HeatmapPage extends StatefulWidget {
//   const HeatmapPage({super.key});
//
//   @override
//   State<HeatmapPage> createState() => _HeatmapPageState();
// }
//
// class _HeatmapPageState extends State<HeatmapPage> {
//   File? _imageFile;
//   Uint8List? _overlayBytes;
//   Uint8List? _heatmapBytes;
//   String? _predLabel;
//   List<double>? _probs;
//   bool _loading = false;
//
//   final ImagePicker _picker = ImagePicker();
//
//   // 1️⃣ اختيار صورة من المعرض
//   Future<void> _pickImage() async {
//     final XFile? pickedFile =
//     await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _imageFile = File(pickedFile.path);
//         _overlayBytes = null;
//         _heatmapBytes = null;
//         _predLabel = null;
//         _probs = null;
//       });
//       _uploadImage(File(pickedFile.path));
//     }
//   }
//
//   // 2️⃣ رفع الصورة إلى السيرفر واستقبال النتيجة
//   Future<void> _uploadImage(File imageFile) async {
//     setState(() {
//       _loading = true;
//     });
//
//     var request = http.MultipartRequest(
//         'POST', Uri.parse('$baseUrl1/ai/predict'));
//     request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
//
//     var response = await request.send();
//     var respStr = await response.stream.bytesToString();
//     var data = jsonDecode(respStr);
//
//     setState(() {
//       _predLabel = data['pred_label'];
//       _probs = List<double>.from(data['probs']);
//       _overlayBytes = base64Decode(data['overlay']);
//       _heatmapBytes = base64Decode(data['heatmap']);
//       _loading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Breast Cancer Heatmap"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: _pickImage,
//               child: const Text("Pick Image"),
//             ),
//             const SizedBox(height: 20),
//             _loading
//                 ? const CircularProgressIndicator()
//                 : _overlayBytes != null
//                 ? Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     Text(
//                       "Prediction: $_predLabel",
//                       style: const TextStyle(
//                           fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       "Probabilities: ${_probs?.map((e) => e.toStringAsFixed(2)).join(', ')}",
//                     ),
//                     const SizedBox(height: 20),
//                     _overlayBytes != null
//                         ? Image.memory(_overlayBytes!)
//                         : Container(),
//                     const SizedBox(height: 20),
//                     _heatmapBytes != null
//                         ? Column(
//                       children: [
//                         const Text("Heatmap Only:"),
//                         Image.memory(_heatmapBytes!),
//                       ],
//                     )
//                         : Container(),
//                   ],
//                 ),
//               ),
//             )
//                 : const Text("No image selected."),
//           ],
//         ),
//       ),
//     );
//   }
// }
