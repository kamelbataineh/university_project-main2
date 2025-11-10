import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:university_project/core/config/theme.dart';
import 'package:university_project/pages/doctor/doctor_intro_page.dart';
import '../auth/register_doctor.dart';
import '../doctor/home_doctor.dart';

class LoginDoctorPage extends StatefulWidget {
  const LoginDoctorPage({Key? key}) : super(key: key);

  @override
  State<LoginDoctorPage> createState() => _LoginDoctorPageState();
}

class _LoginDoctorPageState extends State<LoginDoctorPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool loading = false;
  bool rememberMe = false;

  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _iconController.dispose();
    super.dispose();
  }

  // مجرد تصميم، لا يتصل بالداتا
  void _loginDoctor() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    Future.delayed(Duration(seconds: 1), () {
      setState(() => loading = false);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeDoctorPage(token: "demo", doctorId: 1)));
    });
  }

  Widget neumorphicTextField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, String? Function(String?)? validator}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [Colors.white, Colors.indigo.shade50.withOpacity(0.3)]),
        boxShadow: [
          BoxShadow(color: Colors.indigo.shade100.withOpacity(0.4), offset: Offset(6, 6), blurRadius: 12),
          BoxShadow(color: Colors.white.withOpacity(0.8), offset: Offset(-6, -6), blurRadius: 12),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: TextStyle(color: AppTheme.doctorPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color:AppTheme.doctorIcon),
          hintText: hint,
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
                  gradient: LinearGradient( colors: [Colors.indigo,Colors.indigo],),
                  boxShadow: [
                    BoxShadow(color: Colors.indigo.shade200.withOpacity(0.5), blurRadius: 20, offset: Offset(0, 8)),
                    BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8, offset: Offset(-4, -4), spreadRadius: 1),
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 20),
            floatingHeartIcon(),
            SizedBox(height: 16),
            Text(
              'Doctor Login',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(colors: [Colors.indigo.shade200, Colors.indigo.shade400])
                      .createShader(Rect.fromLTWH(0, 0, 200, 0)),
              ),
            ),
            SizedBox(height: 8),
            Text('Welcome back! Sign in to continue', style: TextStyle(color: Colors.grey.shade600)),
            SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  neumorphicTextField(controller: _email, hint: 'Email', icon: Icons.email_outlined, validator: (val) => val!.isEmpty ? 'Please enter your email' : null),
                  neumorphicTextField(controller: _password, hint: 'Password', icon: Icons.lock_outline, obscure: true, validator: (val) => val!.isEmpty ? 'Please enter your password' : null),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (val) => setState(() => rememberMe = val ?? false),
                            activeColor: Colors.pink.shade200,
                          ),
                          Text('Remember me', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                      TextButton(onPressed: () {}, child: Text('Forgot Password?', style: TextStyle(color: AppTheme.doctorTextBotton))),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : _loginDoctor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.doctorElevatedButtonbackgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: loading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? "),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorIntroPage())),
                        child: Text('Register', style: TextStyle(color:AppTheme.doctorTextBotton)),
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
