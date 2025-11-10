import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:university_project/core/config/theme.dart';
import 'package:university_project/pages/auth/LandingPage.dart';
import 'package:university_project/pages/auth/patient_login_page.dart';
import 'package:university_project/pages/auth/register_doctor.dart';
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

  // ==== Register Patient ====
  Future<void> registerPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final Map<String, dynamic> data = {
      "username": _email.text.trim(),
      "email": _email.text.trim(),
      "first_name": _firstName.text.trim(),
      "last_name": _lastName.text.trim(),
      "password": _password.text.trim(),
      "role": "patient",
      "phone_number": _phoneNumber.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}patients/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final resBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content:
            Text("Welcome ${_firstName.text.trim()} ${_lastName.text.trim()}! Registration has been successfully completed"),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => PatientLoginPage()),
          );
        });
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [Colors.white, Colors.pink.shade100.withOpacity(0.3)]),
            boxShadow: [
              BoxShadow(color: Colors.pink.shade100.withOpacity(0.9), offset: Offset(6, 6), blurRadius: 12),
              BoxShadow(color: Colors.white.withOpacity(0.5), offset: Offset(-6, -6), blurRadius: 12),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator,
            style: TextStyle(color: Colors.pink.shade900),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 16),
              prefixIcon: Icon(icon, color: Colors.pink.shade200),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              errorStyle:  TextStyle(height: 0),
            ),
          ),
        ),
        Builder(
          builder: (context) {
            final errorText = _showErrors ? validator?.call(controller.text) : null;            return errorText != null
                ? Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Text(
                errorText,
                style:  TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
              ),
            )
                :  SizedBox.shrink();
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
                  gradient: LinearGradient(colors: [
                    Colors.pink.shade200,
                    Colors.pinkAccent.shade200
                  ],),
                  boxShadow: [BoxShadow(color: Colors.pink.shade200.withOpacity(0.5),
                        blurRadius: 20,
                        offset: Offset(0, 8)),
                    BoxShadow(color: Colors.white.withOpacity(0.5),
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
                    icon: Icon(Icons.arrow_back, color:AppTheme.patientIcon),
                    onPressed: () => Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (_) => LandingPage())),
                  ),
                   Spacer(),
                  Text(
                    'User Registration',
                    style: TextStyle(
                      color:AppTheme.patientAppbar,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
                      obscure: true,
                      validator: (val) =>
                      val!.isEmpty ? 'Enter password' : null,
                    ),
                     SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : registerPatient,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.patientElevatedButtonbackgroundColor,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: loading
                            ?  CircularProgressIndicator(
                            color: Colors.white)
                            :  Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.patientElevatedButtonText,
                          ),
                        ),
                      ),
                    ),
                    if (loading)  SizedBox(width: 12),
                    if (loading)
                      GestureDetector(
                        onTap: () => setState(() => loading = false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:  Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),

                     SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => PatientLoginPage())),
                          child: Text(
                            'Login',
                            style:
                            TextStyle(color:AppTheme.patientTextBotton),
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
}
