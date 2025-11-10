import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:university_project/pages/auth/patient_login_page.dart';
import 'package:university_project/pages/auth/register_patient.dart';
import 'package:university_project/pages/doctor/doctor_choice_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int currentIndex = 0;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {

    _iconController.dispose();
    super.dispose();
  }

  // 🌟 اسم التطبيق: الأمل - MediCare Future
// 📌 نبذة عن المشروع:
// تطبيق الأمل يساعد المرضى المصابين بالسرطان على متابعة حالتهم الصحية
// وتحليل البيانات الطبية باستخدام تقنيات الذكاء الاصطناعي.
// التطبيق يعمل تحت إشراف الطبيب ولا يقوم بالتشخيص تلقائيًا، بل يقدم الدعم
// والمعلومات ويتيح التواصل المباشر مع الطبيب المتابع للحالة.

  List<Map<String, dynamic>> introPages = [
    {
      "title": "Welcome to MediCare Future", // مرحبًا بك في الأمل
      "subtitle": "A platform to empower cancer patients with AI-assisted insights under doctor supervision.",
      // منصة لتمكين مرضى السرطان من الحصول على تحليلات مدعومة بالذكاء الصناعي تحت إشراف الطبيب.
      "icon": Icons.favorite,
      "gradient": [
        Colors.pink.shade400,
        Colors.pink.shade500,
        Colors.pink.shade600
      ],
    },
    {
      "title": "Secure & Private", // آمن وخاص
      "subtitle": "Your medical data is fully protected and confidential at all times.",
      // بياناتك الطبية محمية وسرية بالكامل في جميع الأوقات.
      "icon": Icons.shield,
      "gradient": [Colors.purple.shade400, Colors.indigo.shade500],
    },
    {
      "title": "Continuous Support", // دعم متواصل
      "subtitle": "Access guidance and real-time advice anytime, staying connected with your doctor.",
      // الوصول إلى الإرشادات والنصائح الفورية في أي وقت، مع الحفاظ على التواصل مع طبيبك.
      "icon": Icons.access_time,
      "gradient": [Colors.orange.shade400, Colors.deepOrange.shade500],
    },
    {
      "title": "Real-time Health Monitoring", // متابعة صحية لحظية
      "subtitle": "Track your progress, receive insights, and feel empowered in your treatment journey.",
      // تتبع تقدمك، احصل على تحليلات، واشعر بالقوة خلال رحلتك العلاجية.
      "icon": Icons.monitor_heart,
      "gradient": [Colors.teal.shade400, Colors.green.shade500],
    },
  ];

  Widget _buildPage(Map<String, dynamic> page) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
                  offset: Offset(0, 10))
            ],
          ),
          child: Icon(page["icon"], color: Colors.white, size: 60),
        ),
        SizedBox(height: 32),
        Text(
          page["title"],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(
          page["subtitle"],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }
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
                  boxShadow: [
                    BoxShadow(color: Colors.pink.shade200.withOpacity(0.5),
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
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: introPages.length + 1, // آخر صفحة للاختيار
              onPageChanged: (index) => setState(() => currentIndex = index),
              itemBuilder: (context, index) {
                if (index < introPages.length) {
                  return _buildPage(introPages[index]);
                } else {
                  // الصفحة الأخيرة: كرت المريض فقط + نص للدكاترة
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Column(
                      children:
                      [

                        Text(
                          "Get Started",
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: width > 600 ? width / 2 - 24 : width - 32,
                          child: _roleCard(
                            title: "User",
                            description:
                            "Access healthcare services, manage health records, and connect with professionals",
                            icon: Icons.person,
                            gradient: [
                              Colors.pink.shade200,
                              Colors.pinkAccent.shade200,
                            ],

                            onCreate: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RegisterPatientPage())), // التسجيل كعضو
                            onLogin: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PatientLoginPage())), // تسجيل الدخول
                          ),
                        ),

                        SizedBox(height: 24),
                        // نص دعائي للدكاترة
                        GestureDetector(
                          onTap: () =>  Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => DoctorChoicePage())),
                          child: Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: LinearGradient(colors: [
                                Colors.purple.shade100.withOpacity(0.3),
                                Colors.indigo.shade100.withOpacity(0.3)
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 12,
                                    offset: Offset(8, 8)),
                                BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 12,
                                    offset: Offset(-8, -8)),
                              ],
                            ),
                            child: Column(
                              children: [

                                Icon(Icons.medical_services,
                                    color: Colors.indigo, size: 36),
                                SizedBox(height: 12),
                                Text(
                                  "Are you a doctor?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Join our platform to help patients and make a difference in healthcare!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          // نقاط التقدم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(introPages.length + 1, (index) {
              return Container(
                margin: EdgeInsets.all(4),
                width: currentIndex == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: currentIndex == index ? Colors.pink : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          SizedBox(height: 16),
          // // زر التالي
          // if (currentIndex < introPages.length)
          //   ElevatedButton(
          //     onPressed: () {
          //       _pageController.nextPage(
          //           duration: Duration(milliseconds: 500),
          //           curve: Curves.easeInOut);
          //     },
          //     style: ElevatedButton.styleFrom(
          //       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          //       backgroundColor: Colors.pink.shade400,
          //     ),
          //     child: const Text("Next", style: TextStyle(color: Colors.white)),
          //   ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _roleCard(
      {required String title,
      required String description,
      required IconData icon,
      required List<Color> gradient,
      VoidCallback? onCreate,
      required VoidCallback onLogin}) {
    return GestureDetector(
      onTap: onCreate,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(colors: [
              Colors.purple.shade100.withOpacity(0.3),
              Colors.indigo.shade100.withOpacity(0.3)
            ]),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 12,
                  offset: Offset(8, 8)),
              BoxShadow(
                  color: Colors.white,
                  blurRadius: 12,
                  offset: Offset(-8, -8)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradient),
                  boxShadow: [
                    BoxShadow(
                        color: gradient[0].withOpacity(0.4),
                        blurRadius: 12,
                        offset: Offset(0, 6)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 36),
              ),
              SizedBox(height: 16),
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(colors: gradient)
                            .createShader(Rect.fromLTWH(0, 0, 200, 0)))),
              SizedBox(height: 8),
              Text(description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: onCreate,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: gradient[0],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('   Create Account   ',
                    style: TextStyle(color: Colors.white)),
              ),
              OutlinedButton(
                onPressed: onLogin,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: gradient[0].withOpacity(0.7)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.white.withOpacity(0.8),
                ),
                child: Text(' Login ', style: TextStyle(color: gradient[0])),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
