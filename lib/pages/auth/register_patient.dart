import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:university_project/core/config/theme.dart';
import 'package:university_project/pages/auth/LandingPage.dart';
import 'package:university_project/pages/auth/patient_login_page.dart';
import 'package:university_project/pages/auth/register_doctor.dart';
import '../../core/config/app_font.dart';
import '../patient/patient_verify_otp_page.dart';
import 'VerifyOtpPage.dart';
import 'doctor_login_page.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

class RegisterPatientPage extends StatefulWidget {
  const RegisterPatientPage({Key? key}) : super(key: key);

  @override
  State<RegisterPatientPage> createState() => _RegisterPatientPageState();
}

class _RegisterPatientPageState extends State<RegisterPatientPage>
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
  bool hasSpecialChar(String password) => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  bool _showPasswordRequirements = false;

  String? validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Confirm your password';
    if (val != _password.text.trim()) return 'Passwords do not match';
    return null;
  }

  bool _obscure = true;

  bool _showErrors = false;
  bool loading = false;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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


  String truncateUtf8(String input, int maxBytes) {
    List<int> bytes = utf8.encode(input);
    if (bytes.length <= maxBytes) return input;
    int i = maxBytes;
    while (i > 0 && (bytes[i] & 0xC0) == 0x80) {
      i--; // تجنب تقطيع بايت UTF-8 نص نصف حرف
    }
    return utf8.decode(bytes.sublist(0, i));
  }

  //
  // Future<void> registerPatient() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   setState(() => loading = true);
  //
  //   // ==================== قص الباسورد قبل الإرسال ====================
  //   final passwordToSend = truncateUtf8(_password.text.trim(), 72);
  //
  //   final Map<String, dynamic> data = {
  //     "username": _email.text.trim(),
  //     "email": _email.text.trim(),
  //     "first_name": _firstName.text.trim(),
  //     "last_name": _lastName.text.trim(),
  //     "password": passwordToSend,  // ← استخدم النسخة المقصوصة
  //     "role": "patient",
  //     "phone_number": _phoneNumber.text.trim(),
  //   };
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse("${baseUrl}patients/register"),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(data),
  //     );
  //
  //     final resBody = jsonDecode(response.body);
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           backgroundColor: Colors.green,
  //           content: Text(
  //               "Welcome ${_firstName.text.trim()} ${_lastName.text.trim()}! Registration has been successfully completed"),
  //         ),
  //       );
  //
  //       Future.delayed(const Duration(seconds: 2), () {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (_) => PatientLoginPage()),
  //         );
  //       });
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           backgroundColor: Colors.redAccent,
  //           content: Text(resBody["detail"] ?? "Registration failed"),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         backgroundColor: Colors.redAccent,
  //         content: Text("Connection to the server failed: $e"),
  //       ),
  //     );
  //   } finally {
  //     setState(() => loading = false);
  //   }
  // }

  Future<void> sendOtpAndGoToVerification() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _showErrors = true);
      return;
    }

    setState(() => loading = true);

    final Map<String, dynamic> data = {
      "username": _email.text.trim(),
      "email": _email.text.trim(),
      "first_name": _firstName.text.trim(),
      "last_name": _lastName.text.trim(),
      "password": truncateUtf8(_password.text.trim(), 72),
      "phone_number": _phoneNumber.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}patients/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final resBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // انتقل لصفحة OTP
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PatientVerifyOtpPage(
              email: _email.text.trim(),
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              password: truncateUtf8(_password.text.trim(), 72),
              phoneNumber: _phoneNumber.text.trim(),
              username: _email.text.trim(), // عادة username = email
            ),
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(resBody["detail"] ?? "Registration failed"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Connection to the server failed: $e"),
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
              leading: const Icon(Icons.local_hospital_outlined),
              title: const Text('Doctor'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterDoctorPage()),
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
    void Function(String)? onChanged,  int? maxLength, // ← اضف هذا السطر
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
                colors: [Colors.white, Colors.pink.shade100.withOpacity(0.3)]),
            boxShadow: [
              BoxShadow(
                  color: Colors.pink.shade100.withOpacity(0.9),
                  offset: Offset(6, 6),
                  blurRadius: 12),
              BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  offset: Offset(-6, -6),
                  blurRadius: 12),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator,
            onChanged: onChanged,
            style: TextStyle(color: Colors.pink.shade900),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 16),
              prefixIcon: Icon(icon, color: Colors.pink.shade200),
              hintText: hint,
              suffixIcon: suffixIcon,
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              errorStyle: TextStyle(height: 0),

            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(maxLength ),
            ],


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
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
              ),
            )
                : SizedBox.shrink();
          },
        ),
      ],
    );
  }


  //
  // Widget floatingPatientIcon() {
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
  //                       color: Colors.pink.shade200.withOpacity(0.3),
  //                       width: 2,
  //                     ),
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
  //               colors: [Colors.pink.shade300, Colors.pink.shade500],
  //             ),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.pink.shade300.withOpacity(0.6),
  //                 blurRadius: 20,
  //                 offset: const Offset(0, 10),
  //               ),
  //             ],
  //           ),
  //           child: const Icon(Icons.favorite, color: Colors.white, size: 40),
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
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade200, Colors.pinkAccent.shade200],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.pink.shade200.withOpacity(0.5),
                        blurRadius: 20,
                        offset: Offset(0, 8)),
                    BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        offset: Offset(-4, -4),
                        spreadRadius: 1),
                  ],
                ),
                child: Icon(Icons.favorite, color: Colors.white, size: 40),
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
              SizedBox(height: 40),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppTheme.patientIcon),
                    onPressed: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => LandingPage())),
                  ),
                  Spacer(),
                  Text(
                    'User Registration',
                    style: AppFont.regular(
                      size: 22,
                      weight: FontWeight.bold,
                      color: AppTheme.patientAppbar,
                    ),
                  ),

                  Spacer(flex: 2),
                ],
              ),
              SizedBox(height: 20),
              floatingPatientIcon(),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    neumorphicTextField(
                      controller: _firstName,
                      hint: "First Name",
                      icon: Icons.person,
                      validator: (val) =>
                          val!.isEmpty ? 'Enter your first name' : null,
                    ),
                    SizedBox(height: 20),
                    neumorphicTextField(
                      controller: _lastName,
                      hint: "Last Name",
                      icon: Icons.person,
                      validator: (val) =>
                          val!.isEmpty ? 'Enter your last name' : null,
                    ),
                    SizedBox(height: 20),
                    neumorphicTextField(
                      controller: _email,
                      hint: "Email",
                      icon: Icons.email,
                      validator: validateEmail,
                    ),
                    SizedBox(height: 20),
                    neumorphicTextField(
                      controller: _phoneNumber,
                      hint: "Phone Number",
                      icon: Icons.phone,
                      validator: (val) =>
                          val!.isEmpty ? 'Enter phone number' : null,
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
                          color: Colors.pink.shade300,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                      ),
                      maxLength: 20,
                    ),

                  //   neumorphicTextField(
                  //   controller: _password,
                  //   hint: "Password",
                  //   icon: Icons.lock,
                  //   obscure: _obscure,
                  //   validator: (val) {
                  //     if (val!.isEmpty) return 'Enter password';
                  //     if (val.length > 20) return 'Password cannot exceed 20 characters';                      if (!hasMinLength(val)) return 'Password must be at least 8 characters';
                  //     if (!hasNumber(val)) return 'Password must contain at least one number';
                  //     if (!hasSpecialChar(val)) return 'Password must contain at least one special character';
                  //     return null;
                  //   },
                  //   onChanged: (val) {
                  //     setState(() {
                  //       _showPasswordRequirements = val.isNotEmpty;
                  //     });
                  //   },
                  //   suffixIcon: IconButton(
                  //     icon: Icon(
                  //       _obscure ? Icons.visibility_off : Icons.visibility,
                  //       color: Colors.pink.shade300,
                  //     ),
                  //     onPressed: () {
                  //       setState(() {
                  //         _obscure = !_obscure;
                  //       });
                  //     },
                  //   ),
                  //   maxLength: 20, // ← اضف هذا السطر
                  // ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        if (_showPasswordRequirements) ...[
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
                          // لو بدك شرط رابع، مثلاً "Letters, numbers or symbols"
                          _buildPasswordRequirement(
                            "Contains letters, numbers or symbols",
                            _password.text.contains(RegExp(r'[A-Za-z]')) ||
                                hasNumber(_password.text) ||
                                hasSpecialChar(_password.text),
                          ),
                          SizedBox(height: 2),
                        ],

                      ],
                    ),

                    SizedBox(height: 12),
                  neumorphicTextField(
                    controller: _confirmPassword,
                    hint: "Confirm Password",
                    icon: Icons.lock,
                    obscure: _obscure,
                    validator: validateConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.pink.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                    maxLength: 20,
                  ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : sendOtpAndGoToVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.patientElevatedButtonbackgroundColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: loading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Register',
                                style: AppFont.regular(
                                  size: 18,
                                  weight: FontWeight.w600,
                                  color: AppTheme.patientElevatedButtonText,
                                ),
                              ),
                      ),
                    ),
                    if (loading) SizedBox(width: 12),
                    if (loading)
                      GestureDetector(
                        onTap: () => setState(() => loading = false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    SizedBox(height: 22),
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
                          onPressed: () =>Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientVerifyOtpPage(
                                email: _email.text.trim(),
                                firstName: _firstName.text.trim(),
                                lastName: _lastName.text.trim(),
                                password: truncateUtf8(_password.text.trim(), 72),
                                phoneNumber: _phoneNumber.text.trim(),
                                username: _email.text.trim(), // عادة username = email
                              ),
                            ),

                            ),
                          child: Text(
                            'Login',
                            style: AppFont.regular(
                              color: AppTheme.patientTextBotton,
                              size: 14,
                              weight: FontWeight.bold// ممكن تحددي الحجم حسب التصميم
                            ),
                          ),

                        ),
                        SizedBox(height: 22),
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
  Widget _buildPasswordRequirement(String text, bool fulfilled) {
    return Row(
      children: [
        Icon(
          fulfilled ? Icons.check_circle : Icons.cancel,
          color: fulfilled ? Colors.green : Colors.red,
          size: 18,
        ),
        SizedBox(width: 6),
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

}
