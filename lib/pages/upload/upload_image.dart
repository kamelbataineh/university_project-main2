import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// تأكد تضيف dependency لـ image_picker في pubspec.yaml

import 'image_results_page.dart'; // استدعاء صفحة النتائج

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  File? selectedImage;

  final ImagePicker _picker = ImagePicker();

  // اختيار صورة من الكاميرا
  Future<void> _pickFromCamera() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  // اختيار صورة من المعرض
  Future<void> _pickFromGallery() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  // الانتقال لصفحة النتائج
  void _goToResultsPage() {
    if (selectedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageResultsPage(
            imageUrl: selectedImage!.path,
            imageName: selectedImage!.path.split('/').last,
            onNavigate: (screen) {
              if (screen == 'upload-image') {
                Navigator.pop(context);
              }
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // الخلفية المتدرجة + blobs
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF0F6), Color(0xFFEDE9FF), Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 30,
            child: AnimatedBlob(
              color: Colors.pink.shade300.withOpacity(0.3),
              size: 180,
              duration: const Duration(seconds: 7),
            ),
          ),
          Positioned(
            top: 200,
            right: 30,
            child: AnimatedBlob(
              color: Colors.purple.shade300.withOpacity(0.3),
              size: 180,
              duration: const Duration(seconds: 7),
              delay: const Duration(seconds: 2),
            ),
          ),
          Positioned(
            bottom: -30,
            left: width / 2 - 90,
            child: AnimatedBlob(
              color: Colors.indigo.shade300.withOpacity(0.3),
              size: 180,
              duration: const Duration(seconds: 7),
              delay: const Duration(seconds: 4),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // الهيدر
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      border: Border(
                        bottom: BorderSide(color: Colors.white.withOpacity(0.4)),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "📤 Upload Medical Image",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Colors.pink, Colors.red, Colors.purple],
                              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: Colors.black.withOpacity(0.05),
                          ),
                          child: const Text("Back"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // منطقة المعاينة
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 320,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(163, 177, 198, 0.4),
                            offset: Offset(20, 20),
                            blurRadius: 40,
                          ),
                          BoxShadow(
                            color: Color.fromRGBO(255, 255, 255, 0.9),
                            offset: Offset(-20, -20),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(
                          selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.image, size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text("No image selected"),
                          SizedBox(height: 4),
                          Text(
                            "Choose an image to upload",
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // أزرار الكاميرا والمعرض
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Camera"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.image),
                            label: const Text("Gallery"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // زر الرفع
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: _goToResultsPage,
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload Image"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.pinkAccent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // بطاقة التعليمات
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE0F2FF), Color(0xFFD1D5FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child:
                            const Icon(Icons.check_circle, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Upload Guidelines",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text(
                                  "• Supported formats: JPG, PNG, HEIC\n"
                                      "• Maximum file size: 10MB\n"
                                      "• Ensure good lighting and clear image quality\n"
                                      "• AI analysis will be provided after upload",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget للـ blob المتحرك
class AnimatedBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final Duration delay;

  const AnimatedBlob({
    super.key,
    required this.color,
    required this.size,
    this.duration = const Duration(seconds: 7),
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: widget.duration)..repeat();

    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(0.3, -0.5)),
          weight: 33),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.3, -0.5), end: const Offset(-0.2, 0.2)),
          weight: 33),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.2, 0.2), end: Offset.zero),
          weight: 34),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 33),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.9), weight: 33),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 34),
    ]).animate(_controller);

    if (widget.delay != Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.translate(
            offset: _animation.value * widget.size,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.size / 2),
                ),
              ),
            ),
          );
        });
  }
}
