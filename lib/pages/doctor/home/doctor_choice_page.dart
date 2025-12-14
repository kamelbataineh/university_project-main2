import 'package:flutter/material.dart';
import 'package:university_project/core/config/theme.dart';
import '../../../core/config/app_font.dart';
import 'doctor_intro_page.dart';
import '../auth/LoginDoctorPage.dart';
import '../../auth/LandingPage.dart';

class DoctorChoicePage extends StatefulWidget {
  const DoctorChoicePage({Key? key}) : super(key: key);

  @override
  State<DoctorChoicePage> createState() => _DoctorChoicePageState();
}

class _DoctorChoicePageState extends State<DoctorChoicePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  /////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.indigo.shade400),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LandingPage()),
          ),
        ),
        title: SizedBox(),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Circle Logo
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double scale = 0.8 + (_controller.value * 0.05);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.indigo, Colors.indigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      const BoxShadow(
                        color: Colors.white24,
                        blurRadius: 8,
                        offset: Offset(-4, -4),
                      )
                    ],
                  ),
                  child: Icon(Icons.medical_services,
                      color: Colors.white, size: 60),
                ),
              ),
              SizedBox(height: 32),
              Text(
                "Welcome to MediCare",
                style: AppFont.regular(
                  size: 28,
                  weight: FontWeight.bold,
                  color: AppTheme.doctorText,
                ),
                textAlign: TextAlign.center,
              ),

               SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>  LoginDoctorPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.doctorElevatedButtonbackgroundColor,
                    padding:  EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize:  Size(double.infinity, 50),
                  ),
                  child: Text(
                  "Login",
                  style: AppFont.regular(
                    size: 18,
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
              ),
               SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>  DoctorIntroPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade200,
                    padding:  EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize:  Size(double.infinity, 50),
                  ),
                  child:Text(
                    "Register",
                    style: AppFont.regular(
                      size: 18,
                      color: Colors.white,
                      weight: FontWeight.w400,
                    ),
                  ),
                )
                ),
            ],
          ),
        ),
      ),
    );
  }
}
