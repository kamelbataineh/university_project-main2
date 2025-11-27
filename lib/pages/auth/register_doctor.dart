import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:university_project/core/config/theme.dart';
import 'package:university_project/pages/auth/doctor_login_page.dart';
import 'package:university_project/pages/auth/register_patient.dart';
import 'package:university_project/pages/doctor/doctor_choice_page.dart';
import '../../core/config/app_config.dart';
import '../../core/config/app_font.dart';

class RegisterDoctorPage extends StatefulWidget {
  const RegisterDoctorPage({Key? key}) : super(key: key);

  @override
  State<RegisterDoctorPage> createState() => _RegisterDoctorPageState();
}

class _RegisterDoctorPageState extends State<RegisterDoctorPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _confirmPassword  = TextEditingController();
  bool _obscure = true;


  bool loading = false;
  bool _showErrors = false;
  late AnimationController _iconController;

  File? _cvFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _iconController =
    AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  // ==== Validate Email ====
  String? validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Enter your email';
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
    return null;
  }

  // ==== رفع ملف السيرة الذاتية ====

  Future<void> pickCV() async {
    // يسمح بصيغ PDF + كل أنواع الصور
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _cvFile = File(result.files.single.path!);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("CV Selected: ${result.files.single.name}"),
          backgroundColor: Colors.greenAccent.shade400,
        ),
      );
    } else {
      // المستخدم ألغى الاختيار
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No file selected"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  // ==== تسجيل دكتور جديد مع رفع CV ====
  // ==== تسجيل دكتور جديد مع رفع CV ====
  Future<void> registerDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cvFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload your CV before submitting"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final uri = Uri.parse(doctorRegister);
      var request = http.MultipartRequest('POST', uri);

      // 🧾 نضيف البيانات النصية
      request.fields['username'] = _email.text.trim();
      request.fields['email'] = _email.text.trim();
      request.fields['first_name'] = _firstName.text.trim();
      request.fields['last_name'] = _lastName.text.trim();
      request.fields['password'] =
          _password.text.trim().substring(0, min(_password.text.trim().length, 72));
      request.fields['role'] = "doctor";
      request.fields['phone_number'] = _phoneNumber.text.trim();

      // 📎 نضيف ملف السيرة الذاتية
      request.files.add(
        await http.MultipartFile.fromPath('cv_file', _cvFile!.path),
      );

      // 🧠 إرسال الطلب
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final decoded = jsonDecode(resBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        String cvUrl = decoded["cv_url"] ?? "No CV URL returned";

        // 🎉 عرض رسالة نجاح + رابط CV + تنبيه بالموافقة على الإيميل
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("تم التسجيل بنجاح ✅"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "تم إرسال طلب التسجيل الخاص بك بنجاح بانتظار موافقة الإدارة.\n\n"
                      "سيصلك إشعار على بريدك الإلكتروني فور الموافقة. 🌸",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text("CV URL: $cvUrl",
                    style: const TextStyle(color: Colors.blue, fontSize: 14)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorChoicePage()),
                  );
                },
                child: const Text("حسناً"),
              ),
            ],
          ),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(decoded["detail"] ?? "Registration failed"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Connection error: $e"),
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }


  void _showRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose another account type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Patient'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPatientPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget neumorphicTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,  int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.indigo.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.shade100.withOpacity(0.6),
                offset: const Offset(6, 6),
                blurRadius: 12,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(-6, -6),
                blurRadius: 12,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator,
            style: TextStyle(color:AppTheme.doctorText ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color:AppTheme.doctorIcon),
              hintText: hint,
              suffixIcon: suffixIcon,
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              errorStyle: const TextStyle(height: 0),
            ),
          ),
        ),
        Builder(
          builder: (context) {
            final errorText =
            _showErrors ? validator?.call(controller.text) : null;
            return errorText != null
                ? Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Text(
                errorText,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
              ),
            )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
  //
  // Widget floatingDoctorIcon() {
  //   return SizedBox(
  //     height: 150,
  //     child: Stack(
  //       alignment: Alignment.center,
  //       children: [
  //         for (int i = 0; i < 3; i++)
  //           AnimatedBuilder(
  //             animation: _iconController,
  //             builder: (context, child) {
  //               double scale = 0.8 + 0.7 * _iconController.value;
  //               return Transform.scale(
  //                 scale: scale,
  //                 child: Container(
  //                   width: 60.0 + i * 30,
  //                   height: 60.0 + i * 30,
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     border: Border.all(
  //                         color: Colors.pink.shade200.withOpacity(0.3),
  //                         width: 2),
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //         Container(
  //           width: 80,
  //           height: 80,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             gradient: LinearGradient(
  //                 colors: [Colors.pink.shade300, Colors.pink.shade500]),
  //             boxShadow: [
  //               BoxShadow(
  //                   color: Colors.pink.shade300.withOpacity(0.6),
  //                   blurRadius: 20,
  //                   offset: const Offset(0, 10)),
  //             ],
  //           ),
  //           child: const Icon(Icons.medical_services,
  //               color: Colors.white, size: 40),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget floatingPatientIcon() {
    return SizedBox(
      height: 120,
      child: Center(
        child: AnimatedBuilder(
          animation: _iconController,
          builder: (context, child) {
            double scale = 1 + 0.05 * _iconController.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Colors.indigo,
                    Colors.indigo
                  ],),
                  boxShadow: [
                    BoxShadow(color: Colors.indigo.shade200.withOpacity(0.5),
                        blurRadius: 20,
                        offset: Offset(0, 8)),
                    BoxShadow(color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        offset: Offset(-4, -4),
                        spreadRadius: 1),
                  ],
                ),
                child: Icon(Icons.medical_services, color: Colors.white, size: 40),
              ),
            );
          },
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.indigo.shade400),
                    onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>  DoctorChoicePage())),
                  ),
                   Spacer(),
                  Text(
                    'Doctor Registration',
                  style: AppFont.regular(
                      size: 22,
                      weight: FontWeight.bold,
                      color: Colors.indigo.shade400,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 20),
              floatingPatientIcon(),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    neumorphicTextField(
                        controller: _firstName,
                        hint: "First Name",
                        icon: Icons.person,
                        validator: (val) =>
                        val!.isEmpty ? 'Enter your first name' : null),
                    const SizedBox(height: 20),
                    neumorphicTextField(
                        controller: _lastName,
                        hint: "Last Name",
                        icon: Icons.person,
                        validator: (val) =>
                        val!.isEmpty ? 'Enter your last name' : null),
                    const SizedBox(height: 20),
                    neumorphicTextField(
                        controller: _email,
                        hint: "Email",
                        icon: Icons.email,
                        validator: validateEmail),
                    const SizedBox(height: 20),
                    neumorphicTextField(
                        controller: _phoneNumber,
                        hint: "Phone Number",
                        icon: Icons.phone,
                        validator: (val) =>
                        val!.isEmpty ? 'Enter phone number' : null),
                    const SizedBox(height: 20),


                    neumorphicTextField(
                      controller: _password,
                      hint: "Password",
                      icon: Icons.lock,
                      obscure: _obscure,
                      maxLength: 20, // الحد الأقصى 20 حرف
                      validator: (val) => val!.isEmpty ? 'Enter password' : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.indigo.shade200,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                      ),
                    ),


                    const SizedBox(height: 20),
                    neumorphicTextField(
                      controller: _confirmPassword,
                      hint: "Confirm Password",
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      maxLength: 20, // الحد الأقصى 20 حرف
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Confirm your password';
                        if (val != _password.text) return 'Passwords do not match';
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.indigo.shade200,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),


                    // 📎 زر رفع السيرة الذاتية
                    ElevatedButton.icon(
                      onPressed: pickCV,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.doctorElevatedButtonbackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label:Text(
                        _cvFile == null ? "Upload CV (PDF/Image)" : "CV Selected ✅",
                        style: AppFont.regular(
                          size: 16,
                          color: Colors.white,
                        ),
                      ),

                    ),

                    const SizedBox(height: 20),

                    // زر التسجيل
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : registerDoctor,
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.doctorElevatedButtonbackgroundColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: loading
                                ?  CircularProgressIndicator(
                                color: Colors.white)
                                :  Text(
                              'Register',
                              style: AppFont.regular(
                                size: 18,
                                weight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: AppFont.regular(
                            size: 14,
                            color: Colors.black, // ممكن تغيّري اللون حسب التصميم
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginDoctorPage())),
                          child: Text(
                            'Login',
                            style: AppFont.regular(
                              size: 14,
                              weight: FontWeight.bold,
                              color: AppTheme.doctorTextBotton,
                            ),
                          ),

                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
