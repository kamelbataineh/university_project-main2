import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:university_project/core/config/theme.dart';
import 'package:university_project/pages/doctor/auth/LoginDoctorPage.dart';
import 'package:university_project/pages/auth/RegisterPatientPage.dart';
import 'package:university_project/pages/doctor/home/doctor_choice_page.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_font.dart';
import 'DoctorVerifyOtpPage.dart';

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
  final TextEditingController _confirmPassword = TextEditingController();

  bool hasMinLength(String password) => password.length >= 8;
  bool hasNumber(String password) => RegExp(r'\d').hasMatch(password);
  bool hasSpecialChar(String password) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

  bool _showPasswordRequirements = false;
  bool _obscure = true;

  Widget _buildPasswordRequirement(String text, bool fulfilled) {
    return Row(
      children: [
        Icon(
          fulfilled ? Icons.check_circle : Icons.cancel,
          color: fulfilled ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppFont.regular(
            size: 13,
            color: fulfilled ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }


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

  Future<void> pickCV() async {
    print("📌 Pick CV: Start");
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _cvFile = File(result.files.single.path!);
      });

      print("✅ CV Selected: ${result.files.single.name}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("CV Selected: ${result.files.single.name}"),
          backgroundColor: Colors.greenAccent.shade400,
        ),
      );
    } else {
      print("❌ No file selected");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No file selected"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> registerDoctor() async {
    print("📌 Register Doctor: Start");

    if (!_formKey.currentState!.validate()) {
      print("❌ Form not valid");
      return;
    }

    if (_cvFile == null) {
      print("❌ CV file is null");
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
      print("🌐 API URL: $uri");

      var request = http.MultipartRequest('POST', uri);
      final username = _email.text.trim().split('@')[0];
      request.fields['username'] = username;
      request.fields['email'] = _email.text.trim();
      request.fields['first_name'] = _firstName.text.trim();
      request.fields['last_name'] = _lastName.text.trim();
      request.fields['password'] = _password.text
          .trim()
          .substring(0, min(_password.text.trim().length, 72));
      request.fields['role'] = "doctor";
      request.fields['phone_number'] = _phoneNumber.text.trim();

      print("📄 Form fields:");
      request.fields.forEach((key, value) => print(" - $key: $value"));

      request.files.add(
        await http.MultipartFile.fromPath('cv_file', _cvFile!.path),
      );
      print("📎 CV file added: ${_cvFile!.path}");

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      print("🌐 Response status: ${response.statusCode}");
      print("🌐 Response body: $resBody");

      final decoded = jsonDecode(resBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        String cvUrl = decoded["cv_url"] ?? "No CV URL returned";
        print("✅ Registration successful, CV URL: $cvUrl");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorVerifyOtpPage(
              email: _email.text.trim(),
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              password: _password.text.trim(),
              phoneNumber: _phoneNumber.text.trim(),
              username: _email.text.trim().split('@')[0],
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم إرسال OTP إلى بريدك الإلكتروني ✅")),
        );
      } else {
        print("❌ Registration failed: ${decoded["detail"]}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(decoded["detail"] ?? "Registration failed"),
          ),
        );
      }
    } catch (e) {
      print("❌ Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Connection error: $e"),
        ),
      );
    } finally {
      setState(() => loading = false);
      print("📌 Register Doctor: End");
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
                  MaterialPageRoute(
                      builder: (_) => const RegisterPatientPage()),
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
    Widget? suffixIcon,
    int? maxLength,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    inputFormatters,
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
                color: Colors.indigo.shade200.withOpacity(0.6),
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
            keyboardType: keyboardType,
            onChanged: onChanged,

            inputFormatters: inputFormatters,
            style: TextStyle(color: AppTheme.doctorText),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.indigo.shade300),
              hintText: hint,
              suffixIcon: suffixIcon,
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),

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

  Widget floatingPatientIcon() {
    return SizedBox(
      height: 130,
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
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.indigo],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.indigo.shade200.withOpacity(0.5),
                        blurRadius: 20,
                        offset: Offset(0, 8)),
                    BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        offset: Offset(-4, -4),
                        spreadRadius: 1),
                  ],
                ),
                child:
                    Icon(Icons.medical_services, color: Colors.white, size: 40),
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
        padding:  EdgeInsets.all(16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // مهم
            children: [
              SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.indigo.shade400),
                      onPressed: () => Navigator.pushReplacement(
                          context, MaterialPageRoute(builder: (_) => DoctorChoicePage())),
                    ),
                  ),
                  Text(
                    'Doctor Registration',
                    style: AppFont.regular(
                      size: 22,
                      weight: FontWeight.bold,
                      color: Colors.indigo.shade400,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),
              floatingPatientIcon(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      neumorphicTextField(
                          controller: _firstName,
                          hint: "First Name",
                          icon: Icons.person,
                          validator: (val) =>
                              val!.isEmpty ? 'Enter your first name' : null),
                      SizedBox(height: 20),
                      neumorphicTextField(
                          controller: _lastName,
                          hint: "Last Name",
                          icon: Icons.person,
                          validator: (val) =>
                              val!.isEmpty ? 'Enter your last name' : null),
                      SizedBox(height: 20),
                      neumorphicTextField(
                          controller: _email,
                          hint: "Email",
                          icon: Icons.email,
                          validator: validateEmail),
                      SizedBox(height: 20),
                      neumorphicTextField(
                        controller: _phoneNumber,
                        hint: "Phone Number",
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10), // 🔒 حماية إضافية
                        ],
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter phone number';
                          }

                          if (val.length != 10) {
                            return 'Phone number must be exactly 10 digits';
                          }

                          if (!val.startsWith('07')) {
                            return 'Phone number must start with 07';
                          }

                          return null;
                        },
                      ),

                      SizedBox(height: 20),
                      neumorphicTextField(
                        controller: _password,
                        hint: "Password",
                        icon: Icons.lock,
                        obscure: _obscure,
                        validator: (val) {
                          if (val!.isEmpty) return 'Enter password';
                          if (val.length > 20) return 'Password cannot exceed 20 characters';
                          if (!hasMinLength(val)) return 'Password must be at least 8 characters';
                          if (!hasNumber(val)) return 'Password must contain at least one number';
                          if (!hasSpecialChar(val)) return 'Password must contain at least one special character';
                          return null;
                        },
                        onChanged: (val) {
                          setState(() {
                            _showPasswordRequirements = val.isNotEmpty;
                          });
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.indigo.shade300,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscure = !_obscure;
                            });
                          },
                        ),
                        maxLength: 20,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(20), // ← يمنع الكتابة بعد 20 حرف
                        ],
                      ),

                      if (_showPasswordRequirements) ...[
                        SizedBox(height: 8),
                        _buildPasswordRequirement(
                          "At least 8 characters",
                          hasMinLength(_password.text),
                        ),
                        _buildPasswordRequirement(
                          "Contains letters and numbers",
                          _password.text.contains(RegExp(r'[A-Za-z]')) && hasNumber(_password.text),
                        ),
                        _buildPasswordRequirement(
                          "Contains at least one special character",
                          hasSpecialChar(_password.text),
                        ),
                        SizedBox(height: 8),
                      ],

                      SizedBox(height: 20),
                      neumorphicTextField(
                        controller: _confirmPassword,
                        hint: "Confirm Password",
                        icon: Icons.lock_outline,
                        obscure: _obscure,
                        maxLength: 20,
                        // الحد الأقصى 20 حرف
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Confirm your password';
                          if (val != _password.text)
                            return 'Passwords do not match';
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.indigo.shade300,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscure = !_obscure;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: 20),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 38, // نفس ارتفاع الأزرار الصغيرة
                            child: ElevatedButton.icon(
                              onPressed: pickCV,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.doctorElevatedButtonbackgroundColor,
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14), // متناسق مع الأزرار الأخرى
                                ),
                              ),
                              icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                              label: Text(
                                _cvFile == null ? "Upload CV (PDF/Image)" : "Change CV",
                                style: AppFont.regular(
                                  size: 13, // حجم الخط صغير ومتناسق
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_cvFile != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (_cvFile != null) {
                                          final path = _cvFile!.path;
                                          await OpenFile.open(path);
                                        }
                                      },
                                      child: Text(
                                        _cvFile!.path.split('/').last,
                                        style: AppFont.regular(size: 14, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _cvFile = null;
                                      });
                                    },
                                    child: const Icon(Icons.close, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width / 2.2,
                          height: 38,
                          child: ElevatedButton(
                            onPressed: loading ? null : registerDoctor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.doctorElevatedButtonbackgroundColor,
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize: const Size(120, 38),
                            ),
                            child: loading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'Register',
                              style: AppFont.regular(
                                size: 13,
                                weight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: AppFont.regular(
                              size: 14,
                              color:
                                  Colors.black, // ممكن تغيّري اللون حسب التصميم
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
                           SizedBox(height: 46),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
