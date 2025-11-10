import 'package:flutter/material.dart';
import 'package:university_project/core/config/theme.dart';
import 'doctor_intro_page.dart';
import '../auth/doctor_login_page.dart';
import '../auth/LandingPage.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.pink.shade400),
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
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.doctorText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginDoctorPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.doctorElevatedButtonbackgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Login",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DoctorIntroPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Register",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
