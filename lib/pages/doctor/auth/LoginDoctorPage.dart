import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:university_project/core/config/theme.dart';
import 'package:university_project/pages/doctor/home/doctor_intro_page.dart';
import 'package:university_project/pages/password/pass_doctor/DoctorForgotPasswordPage.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_font.dart';
import '../home/doctor_choice_page.dart';
import '../home/home_doctor.dart';
import 'package:http/http.dart' as http;

import '../../password/pass_patient/PatientForgotPasswordPage.dart';

class LoginDoctorPage extends StatefulWidget {
  const LoginDoctorPage({Key? key}) : super(key: key);

  @override
  State<LoginDoctorPage> createState() => _LoginDoctorPageState();
}

class _LoginDoctorPageState extends State<LoginDoctorPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool loading = false;
  bool rememberMe = false;
  bool _obscure = true;

  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);
    _loadSavedEmail();

  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _iconController.dispose();
    super.dispose();
  }


  void _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("saved_email") ?? "";
    setState(() {
      _email.text = savedEmail;
    });
  }







  void _loginDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final body = jsonEncode({
        "email": _email.text.trim(),
        "password": _password.text.trim(),
      });

      final response = await http.post(
        Uri.parse(doctorLogin),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['access_token'];
        final doctorId = data['doctor_id'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("role", "doctor");
        await prefs.setString("saved_email_doctor", _email.text.trim());




        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeDoctorPage(token: token, userId: doctorId)),
                (route) => false,
        );
      } else {
        final message = data['detail'] ?? 'حدث خطأ، حاول مرة أخرى';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ في الاتصال بالخادم')));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget neumorphicTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffixIcon, // ← اضف هذا السطر فقط
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            colors: [Colors.white, Colors.indigo.shade50.withOpacity(0.3)]),
        boxShadow: [
          BoxShadow(
              color: Colors.indigo.shade100.withOpacity(0.4),
              offset: Offset(6, 6),
              blurRadius: 12),
          BoxShadow(
              color: Colors.white.withOpacity(0.8),
              offset: Offset(-6, -6),
              blurRadius: 12),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: TextStyle(color: AppTheme.doctorText),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.doctorIcon),
          hintText: hint,
          suffixIcon: suffixIcon,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget floatingHeartIcon() {
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 20),

            Row(
        children: [
        IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.indigo.shade400),
        onPressed: () =>
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => DoctorChoicePage())),
      ),]),
            SizedBox(height: 20),
            floatingHeartIcon(),
            SizedBox(height: 16),
            Text(
              'Doctor Login',
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [
                      Colors.indigo.shade200,
                      Colors.indigo.shade400
                    ],
                  ).createShader(Rect.fromLTWH(0, 0, 200, 0)),
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Welcome back! Sign in to continue',
              style: AppFont.regular(
                size: 14,
                color: Colors.grey.shade600,
              ),
            ),

            SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  neumorphicTextField(
                      controller: _email,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter your email' : null),
                  neumorphicTextField(
                    controller: _password,
                    hint: "Password",
                    icon: Icons.lock,
                    obscure: _obscure,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Checkbox(
                          //   value: rememberMe,
                          //   onChanged: (val) =>
                          //       setState(() => rememberMe = val ?? false),
                          //   activeColor: Colors.pink.shade200,
                          // ),
                          // Text('Remember me',
                          //     style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => Doctorforgotpasswordpage()),
                            );
                          },
                          child:Text(
                            'Forgot Password?',
                            style: AppFont.regular(
                              color: AppTheme.doctorTextBotton,
                              size: 14
                                ,weight: FontWeight.bold
                            ),
                          ),)
                        ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2.2,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: loading ? null : _loginDoctor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.doctorElevatedButtonbackgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14), // متناسق مع الأزرار الأخرى
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
                        'Sign In',
                        style: AppFont.regular(
                          size: 13,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(
                      "Don't have an account? ",
                      style: AppFont.regular(
                        size: 14,
                        color: Colors.black,
                      ),
                    ),

                      TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorIntroPage())),
                child: Text(
                  'Register',
                  style: AppFont.regular(
                    color: AppTheme.doctorTextBotton,
                    size: 14,
                    weight: FontWeight.bold// ممكن تحددي الحجم حسب التصميم
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
    );
  }
}
