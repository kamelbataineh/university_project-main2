import 'package:flutter/material.dart';
import 'package:university_project/pages/auth/LandingPage.dart';
import 'package:university_project/pages/auth/doctor_login_page.dart';
void main() async{

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
// @override
//   void initState(){
//     super.initState();
//     FirebaseAuth.instance.authStateChanges().listen((User? user) {
//       if (user == null) {
//         print('User is currently signed out!');
//       } else {
//         print('User is signed in!');
//       }
//     });
//   }
//


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // initialRoute: "Userorrented",
      // onGenerateRoute: RouteClass.generator,
      home: LandingPage(),
    );

  }



}
// import 'package:flutter/material.dart';
// import 'core/theme/app_theme.dart';
// import 'core/config/app_config.dart';
// import 'pages/auth/login_page.dart';
// import 'pages/doctor/home_doctor.dart';
// import 'pages/patient/home_patient.dart';
//
// void main() {
//   runApp(const SmartClinicApp());
// }
//
// class SmartClinicApp extends StatelessWidget {
//   const SmartClinicApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Smart Clinic',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       home: const LoginPage(),
//       routes: {
//         '/login': (context) => const LoginPage(),
//         '/doctorHome': (context) => const HomeDoctorPage(),
//         '/patientHome': (context) => const HomePatientPage(),
//       },
//     );
//   }
// }
