import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'HeatmapPage(4).dart';

class ImageResultsPage extends StatefulWidget {
  final String imageUrl;
  final String imageName;
  final Function(String) onNavigate;
  final String prediction;
  final List probabilities;
  final List findings;
  final List recommendations;

  const ImageResultsPage({
    super.key,
    required this.imageUrl,
    required this.imageName,
    required this.onNavigate,
    required this.prediction,
    required this.probabilities,
    required this.findings, // ← جديد
    required this.recommendations, // ← جديد

  });

  @override
  State<ImageResultsPage> createState() => _ImageResultsPageState();
}

class _ImageResultsPageState extends State<ImageResultsPage>
    with TickerProviderStateMixin {
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

    final double confidence = maxProb * 100;
    final List findings = widget.findings ?? [];
    final List recommendations = widget.recommendations ?? [];

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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo),
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
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
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
                Icon(Icons.warning_amber,
                    color: getGradientColor(maxProb), size: 18),
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

// 👇 الزر خارج الـ Row
            if (_showConfidence)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.show_chart),
                    label: const Text("View Heatmap"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HeatmapPage(
                            imagePath: widget.imageUrl,           // مسار الصورة
                            prediction: widget.prediction,        // النتيجة الأصلية
                            probabilities: widget.probabilities.map<double>((e) => e.toDouble()).toList(), // الاحتمالات

                          ),
                        ),
                      );
                    },

                  ),
                ),
              ),

            // const SizedBox(height: 16),
            // if (!_isAnalyzing) ...[
            //   const Text(
            //     "Findings:",
            //     style: TextStyle(
            //         fontSize: 18,
            //         fontWeight: FontWeight.bold,
            //         color: Colors.indigo),
            //   ),
            //   const SizedBox(height: 8),
            //   ...findings.map<Widget>((f) {
            //     return Row(
            //       children: [
            //         const Icon(Icons.circle, size: 8, color: Colors.indigo),
            //         const SizedBox(width: 6),
            //         Expanded(
            //             child: Text(f, style: const TextStyle(fontSize: 14))),
            //       ],
            //     );
            //   }).toList(),
              // const SizedBox(height: 16),
              // const Text(
              //   "Recommendations:",
              //   style: TextStyle(
              //       fontSize: 18,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.indigo),
              // ),
              // const SizedBox(height: 8),
              // ...recommendations.map<Widget>((r) {
              //   return Row(
              //     children: [
              //       const Icon(Icons.check_circle,
              //           size: 18, color: Colors.green),
              //       const SizedBox(width: 6),
              //       Expanded(
              //           child: Text(r, style: const TextStyle(fontSize: 14))),
              //     ],
              //   );
              // }).toList(),
              const SizedBox(height: 70),

            //
            // const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   onPressed: (widget.overlayB64.isEmpty || widget.heatmapB64.isEmpty)
            //       ? null // معطل إذا البيانات غير موجودة
            //       : () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (_) => HeatmapPage(
            //
            //         ),
            //       ),
            //     );
            //   },
            //   icon: const Icon(Icons.show_chart),
            //   label: const Text("View Heatmap"),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.indigo.shade400,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //   ),
            // ),

            // ],
          ],
        ),
      ),
    );
  }
}

