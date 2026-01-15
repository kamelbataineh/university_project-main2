import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_font.dart';
import 'HeatmapPage(4).dart';
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
  bool acceptedTerms = false;

  bool isUploading = false;
  double uploadProgress = 0;

  late AnimationController _controller;

  Future<bool> isGrayscale(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) return false;

    const threshold = 210; // فرق أكبر بين R,G,B ليعتبر رمادي (قبل: 15)

    for (int y = 0; y < image.height; y += 10) { // عين كل 10 بيكسل بدل 50 للتأكد
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);

        // جلب قيم R,G,B
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // نقبل الفرق حتى threshold أكبر للرمادي
        if ((r - g).abs() > threshold ||
            (g - b).abs() > threshold ||
            (r - b).abs() > threshold) {
          return false; // صورة ملونة جداً
        }
      }
    }

    return true; // أبيض وأسود / رمادي مسموح
  }



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

    // ===== فحص صيغة الملف =====
    if (!file.path.toLowerCase().endsWith('.png')) {
      showTopSnackBar(context, "❌ Only PNG images are supported");

      return;
    }

    // ===== فحص الحجم =====
    if (file.lengthSync() > 10 * 1024 * 1024) { // 10MB
      showTopSnackBar(context, "❌ Image too large. Max size is 10MB");

      return;
    }

    setState(() {
      selectedImage = file;
    });
  }


  // ================================
  // 2) فلتر للتحقق من صورة الميموجرام



  // ================================
  // 3) رفع الصورة الى FastAPI
  // ================================
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl1/ai/momo'),
    );

    // إضافة الملف
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    // إضافة accepted_terms كـ form field
    request.fields['accepted_terms'] = 'true'; // أو 'false' حسب checkbox

    var response = await request.send();
    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      return json.decode(respStr);
    } else {
      var respStr = await response.stream.bytesToString();
      print(respStr); // لعرض رسالة الخطأ من FastAPI
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

      showTopSnackBar(context, "Please select an image first");

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
            imageUrl: result['image_url'] ?? selectedImage!.path,
            imageName: (result['image_url'] ?? selectedImage!.path).split('/').last,
            onNavigate: (screen) {
              if (screen == 'upload-image') Navigator.pop(context);
            },
            prediction: result['prediction'] ?? "Unknown",
            probabilities: result['probabilities'] ?? [0.0, 0.0, 0.0],
            findings: result['findings'] ?? [],
            recommendations: result['recommendations'] ?? [],

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

  void showTopSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo.shade400,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 100, 16, 50), // ← زودت المسافة من الأعلى
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
            decoration:  BoxDecoration(
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
                          "Select Mammogram",
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
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: acceptedTerms,
                                onChanged: (value) {
                                  setState(() {
                                    acceptedTerms = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  "This AI system provides clinical decision support only. Final medical judgment remains the responsibility of the physician.",
    style: AppFont.regular(
    size: 14,
    weight: FontWeight.bold,
    color: Colors.black,
    ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (selectedImage == null || isUploading) ? null : () async {
                              if (!acceptedTerms) {
                                showTopSnackBar(context, "❌ You must acknowledge the disclaimer first");
                                return;
                              }

                              // فحص PNG
                              if (!selectedImage!.path.toLowerCase().endsWith('.png')) {
                                showTopSnackBar(context, "❌ Only PNG images are supported");
                                return;
                              }

                              // فحص أبيض وأسود
                              bool grayscale = await isGrayscale(selectedImage!);
                              if (!grayscale) {
                                showTopSnackBar(context, "❌ Please upload a grayscale mammogram");
                                return;
                              }

                              // كل شيء تمام → رفع الصورة
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
                              children:  [
                                Text(
                                  "Upload Guidelines",
                                  style: AppFont.regular(
                                    size: 16,
                                    weight: FontWeight.bold,
                                    color: Colors.black,
                                  ),),
                                SizedBox(height: 4),
                                Text(
                                  "• Only mammogram images\n"
                                      "• Supported formats: PNG\n"
                                      "• Maximum file size: 10MB\n"
                                      "• Ensure clear image quality\n"
                                      "• AI analysis provided after upload",
                                  style: AppFont.regular(
                                    size: 14,
                                    weight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          )

                        ],
                      ),
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   child: SizedBox(
                  //     width: double.infinity, // يمتد على كامل العرض
                  //     child: ElevatedButton.icon(
                  //       onPressed: (){  Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (_) => HeatmapPage(
                  //
                  //           ),
                  //         ),
                  //       );},
                  //       icon: const Icon(Icons.image, color: Colors.white), // أيقونة باللون الأبيض
                  //       label: const Text(
                  //         "Choose Image",
                  //         style: TextStyle(color: Colors.white), // نص أبيض
                  //       ),
                  //       style: ElevatedButton.styleFrom(
                  //         padding: const EdgeInsets.symmetric(vertical: 13),
                  //         backgroundColor: Colors.indigo.shade400,
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(16),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),

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
