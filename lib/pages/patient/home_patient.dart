import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:university_project/core/config/app_config.dart';
import 'package:university_project/pages/patient/my_appointments_page.dart';
import '../../core/config/theme.dart';
import 'book_appointment_page.dart';
import 'messages_page.dart';
import 'profile_patient.dart';
import 'dart:ui';

class HomePatientPage extends StatefulWidget {
  final String token;

  const HomePatientPage({Key? key, required this.token}) : super(key: key);

  @override
  State<HomePatientPage> createState() => _HomePatientPageState();
}

class _HomePatientPageState extends State<HomePatientPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late String userId;
  late AnimationController _controller;

  String firstName = '';
  String lastName = '';

  Future<void> fetchPatientName() async {
    final url = Uri.parse(patientMe);
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        firstName = data['first_name'] ?? 'User';
        lastName = data['last_name'] ?? 'User';

      });
    }
  }


  @override
  void initState() {
    super.initState();
    fetchPatientName();
    final decodedToken = JwtDecoder.decode(widget.token);
    userId = decodedToken['sub']?.toString() ??
        decodedToken['user_id']?.toString() ??
        decodedToken['id']?.toString() ??
        '';

    print('🔹 Decoded Token: $decodedToken');


    _controller =
    AnimationController(vsync: this, duration:  Duration(seconds: 7))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  List<Widget> get _pages => [
    _buildDashboard(context),
     MessagesPage(),
    MyAppointmentsPage(token: widget.token),
    ProfilePatientPage(token: widget.token),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        backgroundColor:  AppTheme.patientAppbar,
        elevation: 3,
        centerTitle: true,
        title: Text(
          _selectedIndex == 0
              ? 'Main page'
              : _selectedIndex == 1
              ? 'Messages'
              : _selectedIndex == 2
              ? 'My appointments'
              : 'Personal profile',
          style:  TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon:  Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('🔔 لا توجد إشعارات حالياً')),
              );
            },
          ),
        ],

      ),
      body: Stack(
        children: [

          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: 90 * _controller.value,
                    left: 30,
                    child: _buildBlurCircle( AppTheme.patientAppbar),
                  ),
                  Positioned(
                    top: 200 - 100 * _controller.value,
                    right: 40,
                    child: _buildBlurCircle( AppTheme.patientAppbar),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 120 - 50 * _controller.value,
                    child: _buildBlurCircle( AppTheme.patientAppbar),
                  ),
                ],
              );
            },
          ),
          _pages[_selectedIndex],
        ],
      ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, -4)
              ),
            ],
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: _buildNavItem(Icons.home_outlined, 'Home', 0)),
              Expanded(child: _buildNavItem(Icons.message_outlined, 'Messages', 1)),
              Expanded(child: _buildNavItem(Icons.calendar_today_outlined, 'Appointments', 2)),
              Expanded(child: _buildNavItem(Icons.person_outline, ' Personal profile', 3)),
            ],
          ),
        ),

    );
  }Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ?  AppTheme.patientAppbar : Colors.grey,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFFE91E63) : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {
        "title": "Book appointment",
        "icon": Icons.calendar_today,
        "color1": Colors.pink.shade400,
        "color2": Colors.pink.shade300,
        "page": BookAppointmentPage(userId: userId, token: widget.token),
      },
      // {
      //   "title": "رفع صورة",
      //   "icon": Icons.upload_file,
      //   "color1": Colors.purple.shade400,
      //   "color2": Colors.indigo.shade400,
      //   "page": const UploadImagePage(),
      // },
      // {
      //   "title": "عرض النتائج",
      //   "icon": Icons.bar_chart_outlined,
      //   "color1": Colors.indigo.shade400,
      //   "color2": Colors.purple.shade400,
      //   "page": const ResultsPage(),
      // },
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Welcome, $firstName $lastName ',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [Colors.black,  Colors.pinkAccent.shade200
                  ],
                ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
            ),
          ),
           SizedBox(height: 10),
          Text(
            'Manage your appointments, upload medical images, and view results easily.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 30),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final feature = features[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => feature["page"] as Widget)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [feature["color1"], feature["color2"]],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: feature["color1"].withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(5, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(feature["icon"], color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        feature["title"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  // --------------------------- دائرة ضبابية ---------------------------
  Widget _buildBlurCircle(Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(60),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: 120,
          height: 120,
          color: color.withOpacity(0.4),
        ),
      ),
    );
  }
}

// --------------------------- صفحة الرسائل ---------------------------