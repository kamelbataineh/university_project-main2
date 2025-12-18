import 'package:flutter/material.dart';
import 'package:university_project/core/config/theme.dart';
import '../../../core/config/app_font.dart';
import '../auth/RegisterDoctorPage.dart';
import 'doctor_choice_page.dart';

class DoctorIntroPage extends StatefulWidget {
  const DoctorIntroPage({Key? key}) : super(key: key);

  @override
  State<DoctorIntroPage> createState() => _DoctorIntroPageState();
}

class _DoctorIntroPageState extends State<DoctorIntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.indigo.shade400),
                    onPressed: () =>
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DoctorChoicePage())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: introPages.length,
                itemBuilder: (context, index) => _buildPage(introPages[index]),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                introPages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.indigo
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
             SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _currentPage == introPages.length - 1
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterDoctorPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.doctorElevatedButtonbackgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        "Register Now",
                        style: AppFont.regular(
                          size: 18,
                          color: Colors.white,
                          weight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

  final List<Map<String, dynamic>> introPages = [
    {
      "title": "Welcome to MediCare Future",
      "subtitle": "Advanced healthcare at your fingertips.",
      "icon": Icons.favorite,
      "gradient": [
        Colors.pink.shade400,
        Colors.pink.shade500,
        Colors.pink.shade600
      ],
    },
    {
      "title": "Important Step",
      "subtitle":
          "You need to upload your CV during registration to be evaluated by the administration before activation.",
      "icon": Icons.description,
      "gradient": [Colors.orange.shade400, Colors.deepOrange.shade500],
    },
    {
      "title": "Please Note",
      "subtitle":
          "After uploading your CV, it will be reviewed within 48 hours, and you’ll receive an approval email once accepted.",
      "icon": Icons.watch_later,
      "gradient": [Colors.teal.shade400, Colors.green.shade500],
    },
    {
      "title": "Ready to Join?",
      "subtitle": "Start now and register as a doctor on our medical platform.",
      "icon": Icons.medical_services,
      "gradient": [Colors.indigo.shade400, Colors.indigo.shade600],
    },
  ];

  Widget _buildPage(Map<String, dynamic> page) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Gradient Circle Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: page["gradient"]),
            boxShadow: [
              BoxShadow(
                  color: page["gradient"][0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Icon(page["icon"], color: Colors.white, size: 60),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            page["title"],
            textAlign: TextAlign.center,
            style: AppFont.regular(
              size: 26,
              weight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            page["subtitle"],
            textAlign: TextAlign.center,
            style: AppFont.regular(
              size: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
