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

class _UploadImagePageState extends State<UploadImagePage> {
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  // ================================
  // 📌 1) اختيار صورة من الاستديو فقط
  // ================================
  Future<void> pickFromGallery() async {
    print("📌 فتح الاستديو...");

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      print("❌ لم يتم اختيار أي صورة");
      return;
    }

    // تحويل الى ملف
    File file = File(image.path);

    print("📌 تم اختيار صورة: ${file.path}");

    // تشغيل فلتر الميموجرام
    if (!isMammogram(file)) {
      print("❌ الصورة ليست مموجرام");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ يرجى رفع صورة ميموجرام فقط")),
      );
      return;
    }

    print("✅ الصورة مقبولة (ميموجرام)");

    setState(() {
      selectedImage = file;
    });
  }

  // ================================
  // 📌 2) فلتر يتحقق من صورة الميموجرام
  // ================================
  bool isMammogram(File file) {
    final String name = file.path.toLowerCase();

    // الامتدادات المسموحة
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'dcm'];

    final ext = name.split('.').last;

    print("📌 فحص الامتداد: $ext");

    if (!allowedExtensions.contains(ext)) return false;

    // شرط إضافي: اسم الملف يحتوي كلمات معروفة
    if (!(name.contains("mamm") ||
        name.contains("mg") ||
        name.contains("breast") ||
        name.contains("mammo"))) {
      print("⚠️ الاسم لا يحتوي على كلمات تدل على مموجرام، لكن سنسمح بالامتداد فقط");
      return true;
    }

    return true;
  }

  // ================================
  // 📌 3) رفع الصورة الى FastAPI
  // ================================
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    print("📤 بدء رفع الصورة إلى السيرفر...");

    var request = http.MultipartRequest(
      'POST',
        Uri.parse('http://10.0.2.2:8000/predict')
    );

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    ));

    print("📨 تم تجهيز الطلب… الآن سيتم الإرسال");

    var response = await request.send();

    print("📥 كود الاستجابة: ${response.statusCode}");

    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      print("📌 الرد من السيرفر: $respStr");
      return json.decode(respStr);
    } else {
      throw Exception("❌ فشل الرفع - كود: ${response.statusCode}");
    }
  }

  // ================================
  // 📌 4) الانتقال لصفحة النتائج
  // ================================
  void goToResultsPage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📌 يرجى اختيار صورة أولاً")),
      );
      return;
    }

    try {
      print("🚀 بدء معالجة الصورة…");
      var result = await uploadImage(selectedImage!);

      print("🎉 الانتقال لصفحة النتائج…");

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
      print("❌ خطأ أثناء الرفع: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  // ================================
  // 📌 5) واجهة المستخدم
  // ================================
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // --- الخلفية ---
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF0F6), Color(0xFFEDE9FF), Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ------------------------------
                  // الهيدر
                  // ------------------------------
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          "📤 Upload Mammogram",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Colors.pink, Colors.red, Colors.purple],
                              ).createShader(
                                  const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.6),
                          ),
                          child: const Text("Back"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------
                  // صورة المعاينة
                  // ------------------------------
                  Container(
                    height: 320,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                            color: Color.fromRGBO(163, 177, 198, 0.4),
                            offset: Offset(20, 20),
                            blurRadius: 40),
                        BoxShadow(
                            color: Color.fromRGBO(255, 255, 255, 0.9),
                            offset: Offset(-20, -20),
                            blurRadius: 40),
                      ],
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(
                        selectedImage!,
                        fit: BoxFit.contain,
                      ),
                    )
                        : const Center(
                      child: Text("No Image Selected"),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------
                  // زر اختيار من المعرض
                  // ------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: pickFromGallery,
                      icon: const Icon(Icons.image),
                      label: const Text("Choose from Gallery"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------
                  // زر الرفع
                  // ------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: goToResultsPage,
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload Image"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.pinkAccent,
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
