import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:university_project/pages/auth/LandingPage.dart';
import 'package:university_project/pages/patient/home_patient.dart';
import 'package:university_project/pages/doctor/home/home_doctor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InAppWebViewController.setWebContentsDebuggingEnabled(true);

  final initialPage = await getInitialPage();
  runApp(MyApp(initialPage: initialPage));
}

Future<Widget> getInitialPage() async {
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString("role");
  final token = prefs.getString("token") ?? prefs.getString("doctor_token");

  if (token != null && token.isNotEmpty && role != null) {
    if (role == "patient") {
      return HomePatientPage(token: token);
    } else if (role == "doctor") {
      final userId = prefs.getString("doctor_id") ?? "";
      return HomeDoctorPage(token: token, userId: userId);
    }
  }

  return LandingPage(); // إذا ما فيه تسجيل دخول
}
class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🌟 Theme عام لكل التطبيق
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo.shade400, // خلفية AppBar افتراضية
          iconTheme: IconThemeData(
            color: Colors.white, // كل الأسهم والأيقونات في AppBar بيضاء
          ),
          titleTextStyle: TextStyle(
            color: Colors.white, // العنوان أبيض
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true, // توسيط العنوان افتراضياً
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // أي أيقونة عامة في التطبيق أبيض
        ),
      ),

      home: initialPage,
    );
  }
}







//ipconfig لل الامتداد host