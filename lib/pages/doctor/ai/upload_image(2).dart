import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'image_results_page(3).dart';

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage>
    with SingleTickerProviderStateMixin {
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool isUploading = false;
  double uploadProgress = 0;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true); // حركة مستمرة
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================================
  // 1) اختيار صورة من المعرض
  // ================================
  Future<void> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    File file = File(image.path);
    if (!isMammogram(file)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please upload a mammogram image only")),
      );
      return;
    }

    setState(() {
      selectedImage = file;
    });
  }

  // ================================
  // 2) فلتر للتحقق من صورة الميموجرام
  // ================================
  bool isMammogram(File file) {
    final name = file.path.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'dcm'];
    final ext = name.split('.').last;
    if (!allowedExtensions.contains(ext)) return false;
    if (!(name.contains("mamm") ||
        name.contains("mg") ||
        name.contains("breast") ||
        name.contains("mammo"))) {
      return true;
    }
    return true;
  }

  // ================================
  // 3) رفع الصورة الى FastAPI
  // ================================
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/predict'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      return json.decode(respStr);
    } else {
      throw Exception("Upload failed - status code: ${response.statusCode}");
    }
  }

  // ================================
  // 4) الانتقال لصفحة النتائج
  // ================================
  // void goToResultsPage() async {
  //   if (selectedImage == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("📌 Please select an image first")),
  //     );
  //     return;
  //   }
  //   try {
  //     setState(() => isUploading = true);
  //     var result = await uploadImage(selectedImage!);
  //     setState(() => isUploading = false);
  //
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => ImageResultsPage(
  //           imageUrl: selectedImage!.path,
  //           imageName: selectedImage!.path.split('/').last,
  //           onNavigate: (screen) {
  //             if (screen == 'upload-image') Navigator.pop(context);
  //           },
  //           prediction: result['prediction'],
  //           probabilities: result['probabilities'],
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     setState(() => isUploading = false);
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
  //   }
  // }
  void goToResultsPage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📌 Please select an image first")),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0;
    });

    // ========================
    // 1) محاكاة progress bar لمدة 3 ثواني
    // ========================
    const totalDuration = 3; // 3 ثواني
    const tickMs = 50;
    int ticks = (totalDuration * 1000 ~/ tickMs);
    double increment = 100 / ticks;

    Timer.periodic(Duration(milliseconds: tickMs), (timer) {
      setState(() {
        uploadProgress += increment;
        if (uploadProgress >= 100) {
          uploadProgress = 100;
          timer.cancel();
        }
      });
    });

    // ========================
    // 2) رفع الصورة فعليًا في الخلفية
    // ========================
    try {
      var result = await uploadImage(selectedImage!);

      // تأكد أن الـ progress اكتمل قبل الانتقال
      if (uploadProgress < 100) {
        await Future.delayed(
            Duration(milliseconds: ((100 - uploadProgress) * tickMs ~/ increment)));
      }

      setState(() => isUploading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageResultsPage(
            imageUrl: selectedImage!.path,
            imageName: selectedImage!.path.split('/').last,
            onNavigate: (screen) {
              if (screen == 'upload-image') Navigator.pop(context);
            },
            prediction: result['prediction'],
            probabilities: result['probabilities'],
          ),
        ),
      );
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }




  void simulateUpload() {
    setState(() {
      isUploading = true;
      uploadProgress = 0;
    });

    const totalDuration = 3; // 3 ثواني
    const tick = 0.05; // تحديث كل 50ms تقريبًا
    int ticks = (totalDuration / tick).round();
    double increment = 100 / ticks;

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        uploadProgress += increment;
        if (uploadProgress >= 100) {
          uploadProgress = 100;
          isUploading = false;
          timer.cancel();
        }
      });
    });
  }




  // ================================
  // Animated Blob Widget
  // ================================
  Widget animatedBlob(Color color, double size, double xOffset, double yOffset) {
    double newSize = size * 0.7; // تصغير الحجم
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double dx = xOffset * _controller.value;
        double dy = yOffset * _controller.value;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: Container(
        width: newSize,
        height: newSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFC5CAE9), Color(0xFF9FA8DA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Animated blobs
          Positioned(
              top: 50,
              left: 30,
              child: animatedBlob(Colors.indigo.withOpacity(0.3), 150, 30, -50)),
          Positioned(
              top: 150,
              right: 20,
              child: animatedBlob(Colors.indigo.withOpacity(0.3), 150, -30, 50)),
          Positioned(
              bottom: -40,
              left: MediaQuery.of(context).size.width / 2 - 75,
              child: animatedBlob(Colors.indigo.withOpacity(0.3), 150, 20, -30)),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child:
                              const Icon(Icons.arrow_back, color: Colors.indigo),
                            ),
                          ),
                        ),

                        // Centered title
                        Text(
                          "Upload Mammogram",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Colors.indigo, Colors.blue, Colors.indigoAccent],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Image preview
                  Container(
                    height: 320,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                            color: Color.fromRGBO(163, 177, 198, 0.2),
                            offset: Offset(20, 20),
                            blurRadius: 40),
                        BoxShadow(
                            color: Color.fromRGBO(255, 255, 255, 0.2),
                            offset: Offset(-20, -20),
                            blurRadius: 40),
                      ],
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(selectedImage!, fit: BoxFit.contain),
                    )
                        : const Center(child: Text("No Image Selected")),
                  ),

                  const SizedBox(height: 16),

                  // Button: Gallery only
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity, // يمتد على كامل العرض
                      child: ElevatedButton.icon(
                        onPressed: pickFromGallery,
                        icon: const Icon(Icons.image, color: Colors.white), // أيقونة باللون الأبيض
                        label: const Text(
                          "Choose Image",
                          style: TextStyle(color: Colors.white), // نص أبيض
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: Colors.indigo.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Upload button + progress
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (selectedImage == null || isUploading)
                                ? null // معطل إذا ما في صورة أو أثناء التحميل
                                : () {
                              setState(() {
                                isUploading = true;
                                uploadProgress = 0;
                              });
                              goToResultsPage();
                            },
                            icon: const Icon(Icons.upload, color: Colors.white),
                            label: Text(
                              isUploading
                                  ? "Uploading... ${uploadProgress.toInt()}%"
                                  : "Upload Image",
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              backgroundColor: (selectedImage == null || isUploading)
                                  ? Colors.grey // لون رمادي إذا معطل
                                  : Colors.indigo.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),


                        if (isUploading)
                          Padding(
                            padding:  EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(
                              value: uploadProgress / 100,
                              backgroundColor: Colors.grey[300],
                              color: Colors.indigo,
                              minHeight: 6,
                            ),
                          ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 32),

                  // Info Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade100, Colors.indigo.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.indigo.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: Colors.indigo, shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Upload Guidelines",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "• Only mammogram images\n"
                                      "• Supported formats: JPG, PNG\n"
                                      "• Maximum file size: 10MB\n"
                                      "• Ensure clear image quality\n"
                                      "• AI analysis provided after upload",
                                  style: TextStyle(fontSize: 14),
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
