import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';
import '../patient/home_patient.dart';
import 'register_patient.dart';

class PatientLoginPage extends StatefulWidget {
   PatientLoginPage({Key? key}) : super(key: key);

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> with SingleTickerProviderStateMixin {
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    final input = _email.text.trim();
    final password = _password.text.trim();
    final data = <String, String>{
      'email': input,
      'password': password,
    };

    try {
      final response = await http.post(
        Uri.parse(patientLogin),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final resBodyStr = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final resBody = jsonDecode(resBodyStr);
        final token = resBody["access_token"] ?? "";

        // 🟢 إضافة هذه السطور المهمة
        final patientData = resBody["patient_data"] ?? {};
        final firstName = patientData["first_name"] ?? "";
        final lastName = patientData["last_name"] ?? "";

        if (token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("The token has not been received from the server.")),
          );
          return;
        }

        // حفظ البيانات في SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("first_name", firstName);
        await prefs.setString("last_name", lastName);

        // رسالة الترحيب
        String nameMessage;
        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          nameMessage = 'Welcome $firstName $lastName ';
        } else {
          nameMessage = 'Welcome';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.green, content: Text(nameMessage)),
        );

        // الانتقال للصفحة الرئيسية
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePatientPage(token: token)),
          );
        });
      } else {
        String errorMsg = "Connection to the server failed (${response.statusCode})";
        try {
          final resBody = jsonDecode(resBodyStr);
          if (resBody['detail'] != null) errorMsg = resBody['detail'].toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text(errorMsg)),
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



  Widget neumorphicTextField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, String? Function(String?)? validator}) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    Container(
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: LinearGradient(colors: [Colors.white, Colors.pink.shade50.withOpacity(0.3)]),
    boxShadow: [
    BoxShadow(color: Colors.pink.shade100.withOpacity(0.9), offset: Offset(6, 6), blurRadius: 12),
    BoxShadow(color: Colors.white.withOpacity(0.5), offset: Offset(-6, -6), blurRadius: 12),
    ],
    ),

      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: TextStyle(color: Colors.pink.shade800),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.pink.shade200),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),

    )
  ]
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
                  gradient: LinearGradient( colors: [Colors.pink.shade200,Colors.pinkAccent.shade200],),
                  boxShadow: [
                    BoxShadow(color: Colors.pink.shade200.withOpacity(0.5), blurRadius: 20, offset: Offset(0, 8)),
                    BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8, offset: Offset(-4, -4), spreadRadius: 1),
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 20),
            floatingHeartIcon(),
            SizedBox(height: 16),
            Text(
              'User Login',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(colors: [Colors.pink.shade200, Colors.pink.shade400])
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
                 SizedBox(height:20,),
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
                      TextButton(onPressed: () {}, child: Text('Forgot Password?', style: TextStyle(color:AppTheme.patientTextBotton))),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.patientElevatedButtonbackgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: loading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                          color: AppTheme.patientElevatedButtonText)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? "),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPatientPage())),
                        child: Text('Register', style: TextStyle(color:AppTheme.patientTextBotton)),
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
