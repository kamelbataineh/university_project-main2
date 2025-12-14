import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:university_project/pages/components/chats_list_page.dart';
import '../../auth/LandingPage.dart';
import '../ai/upload_image(2).dart';
import '../appointments/doctor_appointments_page.dart';
import '../profile/profile_doctor.dart';
import '../../../core/config/theme.dart';
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
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _pages.addAll([
      _buildDashboard(),
      ChatsListPage(
        userId: widget.userId,
        token: widget.token,
      ),
      UploadImagePage(),
      DoctorAppointmentsPage(token: widget.token , userId: widget.userId),
      ProfileDoctorPage(token: widget.token),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LandingPage()),
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
                offset: const Offset(0, -4))
          ],
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.4))),
        ),
        child: Row(
          children: [
            _buildBottomNavItem(Icons.home_outlined, 'Home', 0),
            _buildBottomNavItem(Icons.message_outlined, 'Messages', 1),
            _buildBottomNavItem(Icons.photo, 'Upload', 2),
            _buildBottomNavItem(
                Icons.calendar_today_outlined, 'Appointments', 3),
            _buildBottomNavItem(Icons.person_outline, 'Profile', 4),
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
            'Welcome, Dr. $doctorName 👨‍⚕️',
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
  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 26,
                  color: isSelected
                      ? AppTheme.doctorElevatedButtonbackgroundColor
                      : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? AppTheme.doctorElevatedButtonbackgroundColor
                      : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
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
        'label': "Total Patients",
        'value': "124",
        'color1': Colors.pink.shade400,
        'color2': Colors.pinkAccent.shade100
      },
      {
        'label': "Today's Scans",
        'value': "8",
        'color1': Colors.purple.shade400,
        'color2': Colors.indigo.shade500
      },
      {
        'label': "Pending Review",
        'value': "3",
        'color1': Colors.orange.shade400,
        'color2': Colors.orange.shade600
      },
      {
        'label': "Completed",
        'value': "115",
        'color1': Colors.green.shade400,
        'color2': Colors.green.shade600
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
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
                offset: Offset(4, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat['label'] as String,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                stat['value'] as String,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
