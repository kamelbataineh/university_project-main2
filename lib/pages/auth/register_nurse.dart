// import 'package:flutter/material.dart';
// import 'package:university_project/pages/auth/register_doctor.dart';
// import 'package:university_project/pages/auth/register_patient.dart';
//
// import 'doctor_login_page.dart';
//
// class RegisterNursePage extends StatefulWidget {
//   const RegisterNursePage({Key? key}) : super(key: key);
//
//   @override
//   State<RegisterNursePage> createState() => _RegisterNursePageState();
// }
//
// class _RegisterNursePageState extends State<RegisterNursePage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _name = TextEditingController();
//   final TextEditingController _email = TextEditingController();
//   final TextEditingController _department = TextEditingController();
//   final TextEditingController _password = TextEditingController();
//   void _showRoleDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Choose another account type'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.person_outline),
//               title: const Text('Patient'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const RegisterPatientPage(),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.local_hospital_outlined),
//               title: const Text('Doctor'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const RegisterDoctorPage(),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         backgroundColor: Colors.teal.shade600,
//         title: const Text('Register as Nurse'),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const LoginPage()),
//             );
//           },
//         ),
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//           child: Column(
//             children: [
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     TextFormField(
//                       controller: _name,
//                       decoration: InputDecoration(
//                         labelText: 'Full Name',
//                         prefixIcon: const Icon(Icons.person_outline),
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(15)),
//                       ),
//                       validator: (val) =>
//                       val!.isEmpty ? 'Enter your name' : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _email,
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         prefixIcon: const Icon(Icons.email_outlined),
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(15)),
//                       ),
//                       validator: (val) =>
//                       val!.isEmpty ? 'Enter your email' : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _department,
//                       decoration: InputDecoration(
//                         labelText: 'Department',
//                         prefixIcon: const Icon(Icons.business_outlined),
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(15)),
//                       ),
//                       validator: (val) =>
//                       val!.isEmpty ? 'Enter your department' : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _password,
//                       obscureText: true,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         prefixIcon: const Icon(Icons.lock_outline),
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(15)),
//                       ),
//                       validator: (val) =>
//                       val!.isEmpty ? 'Enter a password' : null,
//                     ),
//                     const SizedBox(height: 20),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.teal.shade600,
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12)),
//                         ),
//                         onPressed: () {
//                           if (_formKey.currentState!.validate()) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content:
//                                   Text('Nurse registered successfully')),
//                             );
//                           }
//                         },
//                         child: const Text(
//                           'Register',
//                           style: TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     TextButton(
//                       onPressed: _showRoleDialog,
//                       child: const Text(
//                         'Change account type',
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text("Already have an account?"),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (_) =>  LoginPage()),
//                             );
//                           },
//                           child:  Text('Login'),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
