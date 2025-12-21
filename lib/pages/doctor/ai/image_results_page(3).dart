import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

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
class _ImageResultsPageState extends State<ImageResultsPage> with TickerProviderStateMixin {
  bool _isAnalyzing = true;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late ScrollController _scrollController;

  String _confidenceText = "";
  bool _showConfidence = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initAnimations();
  }








  void _startTypingConfidence(String confidence) {
  _confidenceText = "";
  int index = 0;
  Timer.periodic(const Duration(milliseconds: 50), (timer) {
  if (!mounted) {
  timer.cancel();
  return;
  }
  if (index < confidence.length) {
  setState(() {
  _confidenceText += confidence[index];
  });
  index++;
  } else {
  timer.cancel();
  }
  });
  }


  void _initAnimations() {
    _controllers = [];
    _animations = [];
    double maxProb = widget.probabilities.reduce((a, b) => a > b ? a : b);
    final String confidenceStr = (maxProb * 100).toStringAsFixed(1);

    for (var prob in widget.probabilities) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      );
      final animation = Tween<double>(begin: 0, end: prob.toDouble()).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      )..addListener(() {
        setState(() {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      });

      _controllers.add(controller);
      _animations.add(animation);
      controller.forward();
    }

    // بعد انتهاء الأنيميشن، ابدأ الكتابة التدريجية
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _showConfidence = true;
        _startTypingConfidence(confidenceStr);
      });
    });
  }


  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  // اللون المتدرج من أخضر إلى أحمر
  Color getGradientColor(double value) {
    if (value >= 0.7) return Colors.red;
    if (value >= 0.4) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    List<String> classNames = ["benign", "malignant", "normal"];
    double maxProb = widget.probabilities.reduce((a, b) => a > b ? a : b);

    final Map<String, dynamic> results = {
      'confidence': maxProb * 100,
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
        centerTitle: true, // 🟢 لتوسيط العنوان
        title: const Text(
          "Image Analysis",
          style: TextStyle(
            color: Colors.white, // 🟢 لون العنوان أبيض
          ),
        ),
        backgroundColor: Colors.indigo.shade400,
      ),

      body: SingleChildScrollView(
        controller: _scrollController,
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

            Text(
              "Prediction: ${widget.prediction}",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 16),

            ...List.generate(classNames.length, (index) {
              double value = _animations[index].value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${classNames[index]}: ${(value * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                        color: getGradientColor(value),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.warning_amber, color: getGradientColor(maxProb), size: 18),
                const SizedBox(width: 8),
                Text(
                  _showConfidence ? "Confidence: $_confidenceText%" : "",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: getGradientColor(maxProb),
                  ),
                ),
              ],
            ),


            const SizedBox(height: 16),
            if (!_isAnalyzing) ...[
              const Text(
                "Findings:",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 8),
              ...results['findings'].map<Widget>((f) {
                return Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.indigo),
                    const SizedBox(width: 6),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                  ],
                );
              }).toList(),
              const SizedBox(height: 16),
              const Text(
                "Recommendations:",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
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
              const SizedBox(height: 70),
            ],
          ],
        ),
      ),
    );
  }
}



// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'dart:async';
//
// class ImageResultsPage extends StatefulWidget {
//   final String imageUrl;
//   final String imageName;
//   final Function(String) onNavigate;
//   final String prediction;
//   final List probabilities;
//
//   const ImageResultsPage({
//     super.key,
//     required this.imageUrl,
//     required this.imageName,
//     required this.onNavigate,
//     required this.prediction,
//     required this.probabilities,
//   });
//
//   @override
//   State<ImageResultsPage> createState() => _ImageResultsPageState();
// }
//
// class _ImageResultsPageState extends State<ImageResultsPage> {
//   bool _isAnalyzing = true;
//   String _displayedText = "";
//   final String _fullText = "Analyzing image for Pneumonia detection...";
//   Timer? _typingTimer;
//   @override
//   void initState() {
//     super.initState();
//     _simulateTyping();
//   }
//
//
//   @override
//   void dispose() {
//     _typingTimer?.cancel();
//     super.dispose();
//   }
//
//
//
//   void _simulateTyping() {
//     int index = 0;
//     _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
//       if (!mounted) {  // 🟢 تحقق قبل setState
//         timer.cancel();
//         return;
//       }
//       if (index < _fullText.length) {
//         setState(() {
//           _displayedText += _fullText[index];
//         });
//         index++;
//       } else {
//         timer.cancel();
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (!mounted) return;  // 🟢 تحقق قبل setState
//           setState(() {
//             _isAnalyzing = false;
//           });
//         });
//       }
//     });
//   }
//
//   Color severityColor(String severity) {
//     switch (severity) {
//       case 'low':
//         return Colors.green;
//       case 'medium':
//         return Colors.orange;
//       case 'high':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   Icon severityIcon(String severity) {
//     switch (severity) {
//       case 'low':
//         return const Icon(Icons.check_circle, color: Colors.white, size: 18);
//       case 'medium':
//       case 'high':
//         return const Icon(Icons.warning_amber, color: Colors.white, size: 18);
//       default:
//         return const Icon(Icons.info, color: Colors.white, size: 18);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<String> classNames = ["benign", "malignant", "normal"];
//     double maxProb = widget.probabilities.reduce((a, b) => a > b ? a : b);
//     String severity = maxProb > 0.7
//         ? "high"
//         : maxProb > 0.4
//         ? "medium"
//         : "low";
//
//     final Map<String, dynamic> results = {
//       'condition': 'Pneumonia Detection',
//       'confidence': (maxProb * 100),
//       'severity': severity,
//       'findings': [
//         'Consolidation detected in right lower lobe',
//         'Increased opacity in affected area',
//         'No signs of pleural effusion',
//         'Cardiac silhouette within normal limits',
//       ],
//       'recommendations': [
//         'Antibiotic therapy recommended',
//         'Follow-up X-ray in 2 weeks',
//         'Monitor oxygen saturation',
//         'Consider sputum culture if symptoms persist',
//       ],
//     };
//
//     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Image Analysis"),
// //         backgroundColor: Colors.pinkAccent,
// //       ),
// //       body: _isAnalyzing
// //           ? Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             const CircularProgressIndicator(),
// //             const SizedBox(height: 24),
// //             Text(
// //               _displayedText,
// //               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
// //             ),
// //           ],
// //         ),
// //       )
// //           : SingleChildScrollView(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             ClipRRect(
// //               borderRadius: BorderRadius.circular(16),
// //               child: Image.file(
// //                 File(widget.imageUrl),
// //                 width: double.infinity,
// //                 height: 250,
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //             const SizedBox(height: 16),
// //
// //             // Prediction
// //             Text(
// //               "Prediction: ${widget.prediction}",
// //               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 8),
// //
// //             // Probabilities
// //             ...List.generate(classNames.length, (index) {
// //               return Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text("${classNames[index]}: ${(widget.probabilities[index] * 100).toStringAsFixed(1)}%"),
// //                   const SizedBox(height: 4),
// //                   LinearProgressIndicator(
// //                     value: widget.probabilities[index],
// //                     minHeight: 10,
// //                     color: Colors.blueAccent,
// //                     backgroundColor: Colors.grey.shade300,
// //                   ),
// //                   const SizedBox(height: 12),
// //                 ],
// //               );
// //             }),
// //
// //             const SizedBox(height: 16),
// //             // Confidence
// //             Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   "Confidence: ${results['confidence'].toStringAsFixed(1)}%",
// //                   style: const TextStyle(fontSize: 16),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 LinearProgressIndicator(
// //                   value: results['confidence'] / 100,
// //                   backgroundColor: Colors.grey.shade300,
// //                   color: Colors.blueAccent,
// //                   minHeight: 10,
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 16),
// //
// //             // Severity
// //             Row(
// //               children: [
// //                 severityIcon(results['severity']),
// //                 const SizedBox(width: 8),
// //                 Text(
// //                   "Severity: ${results['severity'].toUpperCase()}",
// //                   style: TextStyle(
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.bold,
// //                     color: severityColor(results['severity']),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 16),
// //
// //             // Findings
// //             const Text(
// //               "Findings:",
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 8),
// //             ...results['findings'].map<Widget>((f) {
// //               return Row(
// //                 children: [
// //                   const Icon(Icons.circle, size: 8, color: Colors.black54),
// //                   const SizedBox(width: 6),
// //                   Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
// //                 ],
// //               );
// //             }).toList(),
// //             const SizedBox(height: 16),
// //
// //             // Recommendations
// //             const Text(
// //               "Recommendations:",
// //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 8),
// //             ...results['recommendations'].map<Widget>((r) {
// //               return Row(
// //                 children: [
// //                   const Icon(Icons.check_circle, size: 18, color: Colors.green),
// //                   const SizedBox(width: 6),
// //                   Expanded(child: Text(r, style: const TextStyle(fontSize: 14))),
// //                 ],
// //               );
// //             }).toList(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
