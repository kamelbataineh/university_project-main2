import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:university_project/pages/components/chats_list_page.dart' hide baseUrl;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_font.dart';
import '../../auth/LandingPage.dart';
import '../ai/upload_image(2).dart';
import '../appointments/doctor_appointments_page.dart';
import '../profile/profile_doctor.dart';
import '../../../core/config/theme.dart';
import '../records/DoctorRecordsPage.dart';
////
//
//
//
class HomeDoctorPage extends StatefulWidget {
  final String token;
  final String userId;

  const HomeDoctorPage({Key? key, required this.token, required this.userId})
      : super(key: key);

  @override
  State<HomeDoctorPage> createState() => _HomeDoctorPageState();
}

class _HomeDoctorPageState extends State<HomeDoctorPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  String doctorName = 'Doctor';

  int totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);



    _loadDoctorName(); // هنا
    _loadStats();

  }

  Future<void> _loadStats() async {
    int records = await fetchTotalRecords(widget.token);
    setState(() {
      totalRecords = records;
    });
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  List<Widget> get pages_ {
    return [
      _buildDashboard(),
      ChatsListPage(userId: widget.userId, token: widget.token),
      UploadImagePage(),
      DoctorAppointmentsPage(token: widget.token, userId: widget.userId),
      ProfileDoctorPage(token: widget.token),
    ];
  }



  Future<void> _loadDoctorName() async {
    final url = Uri.parse("$baseUrl1/doctors/me");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        doctorName = "${data['first_name']} ${data['last_name']}";
      });
    } else {
      setState(() {
        doctorName = 'Doctor';
      });
    }
  }

  Future<int> fetchTotalRecords(String token) async {
    final url = Uri.parse("$baseUrl1/api/v1/doctor/my_created_records?page=1&limit=100");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // تأكد من وجود المفتاح total_records
        if (data.containsKey('total_records')) {
          return data['total_records'] ?? 0;
        } else {
          print('Key "total_records" not found in response');
          return 0;
        }
      } else {
        print('Error fetching records: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Exception: $e');
      return 0;
    }
  }

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold( endDrawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.doctorElevatedButtonbackgroundColor,
            ),
            child: Text(
              'Menu',
              style: AppFont.regular(
                size: 20,
                weight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.support_agent, color: Colors.blue),
            title: Text('Technical Support'),
            onTap: () {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'batainehkamel2@gmail.com',
                query: 'subject=Support Request',
              );
              launchUrl(emailLaunchUri);
            },
          ),
        ],
      ),
    ),

      appBar: AppBar(
        title: Text(_selectedIndex == 0
            ? 'Dashboard'
            : _selectedIndex == 1
                ? 'Messages'
                : _selectedIndex == 2
                    ? 'Upload Image'
                    : _selectedIndex == 3
                        ? 'Appointments'
                        : 'Profile'),
        centerTitle: true,
        backgroundColor: AppTheme.doctorElevatedButtonbackgroundColor,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
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
                      child: _buildBlurCircle(
                          AppTheme.doctorElevatedButtonbackgroundColor, 100)),
                  Positioned(
                      top: 200 - 100 * _controller.value,
                      right: 40,
                      child: _buildBlurCircle(
                          AppTheme.doctorElevatedButtonbackgroundColor, 100)),
                  Positioned(
                      bottom: 0,
                      left: 120 - 50 * _controller.value,
                      child: _buildBlurCircle(
                          AppTheme.doctorElevatedButtonbackgroundColor, 100)),
                ],
              );
            },
          ),
          _selectedIndex == 0
              ? _buildDashboard() // Dashboard يبنى حسب البيانات الجديدة
              : pages_[_selectedIndex],
        ]
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.4))),
        ),
        child: Row(
          children: [
            Expanded(child: _buildBottomNavItem(Icons.home_outlined, 'Home', 0)),
            Expanded(child: _buildBottomNavItem(Icons.message_outlined, 'Messages', 1)),
            Expanded(child: _buildBottomNavItem(Icons.photo, 'Upload', 2)),
            Expanded(child: _buildBottomNavItem(Icons.calendar_today_outlined, 'Appointments', 3)),
            Expanded(child: _buildBottomNavItem(Icons.person_outline, 'Profile', 4)),
          ],
        ),

      ),
    );
  }

// Widget   and   Card
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Widget _buildDashboard() {
    final List<Map<String, dynamic>> features = [];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Welcome, Dr. $doctorName',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [
                    Colors.indigo.shade900,
                    AppTheme.doctorElevatedButtonbackgroundColor
                  ],
                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Manage patients, check your appointments, and view your profile.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 30),
          _buildStatsCards(),
          SizedBox(height: 30),
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
                  MaterialPageRoute(builder: (_) => feature["page"] as Widget),
                ),
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

////
////
////
////////////////////////////////
////
////
////
////
////
////
////
////
////
/////////////////////////////////
////
////
////
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_selectedIndex == 0) {
      _loadDoctorName();
      _loadStats();
    }
  }



  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF5EEFF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color:  Colors.indigo.withOpacity(0.65),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected
                  ?  Colors.indigo
                  : Colors.grey.shade500,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12,
                letterSpacing: 0.3,
                color: isSelected
                    ?  Colors.indigo
                    : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


////
////
////
////////////////////////////////
////
////
////
////
////
////
////
////
////
/////////////////////////////////
////
////
////
  Widget _buildBlurCircle(Color color, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          color: color.withOpacity(0.4),
        ),
      ),
    );
  }

////
////
////
////////////////////////////////
////
////
////
////
////
////
////
////
////
/////////////////////////////////
////
////
////
  Widget _buildStatsCards() {
    final stats = [
      {
        'label': "Total Records",
        'value': totalRecords.toString(),
        'color1': Colors.pink.shade400,
        'color2': Colors.pinkAccent.shade100
      },


    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];

        // فقط البطاقة الأولى (Total Records) قابلة للنقر
        return GestureDetector(
          onTap: () {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorRecordsPage(token: widget.token),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [stat['color1'] as Color, stat['color2'] as Color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (stat['color1'] as Color).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(4, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['label'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );

  }

}
