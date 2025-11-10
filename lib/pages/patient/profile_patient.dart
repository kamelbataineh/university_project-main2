import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';

class ProfilePatientPage extends StatefulWidget {
  final String token;
  const ProfilePatientPage({Key? key, required this.token}) : super(key: key);

  @override
  _ProfilePatientPageState createState() => _ProfilePatientPageState();
}

class _ProfilePatientPageState extends State<ProfilePatientPage> {
  Map<String, dynamic>? patientData;
  bool isLoading = true;
  bool isEditing = false;
  String editingField = '';
  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatientProfile();
  }

  Future<void> fetchPatientProfile() async {
    final url = Uri.parse(patientMe);
    final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});

    if (response.statusCode == 200) {
      setState(() {
        patientData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Error: ${response.body}');
    }
  }

  Future<void> _updateField(String field, String currentValue,
      {String? secondField, String? secondValue}) async {
    controller1.text = currentValue;
    if (secondField != null && secondValue != null) controller2.text = secondValue;

    setState(() {
      isEditing = true;
      editingField = field;
    });
  }

  Future<void> _saveField() async {
    if (patientData == null) return;
    Map<String, String> body = {editingField: controller1.text};
    if (editingField == "name") {
      body = {"first_name": controller1.text, "last_name": controller2.text};
    }

    final url = Uri.parse(patientMeUpdate);
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      fetchPatientProfile();
      setState(() {
        isEditing = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ، حاول لاحقاً")),
      );
    }
  }

  Widget neumorphicInput({required String label, required TextEditingController controller, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF0F0F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.grey, offset: Offset(6, 6), blurRadius: 10),
          BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.pink) : null,
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget profileCard({required String title, required String value, IconData? icon, required VoidCallback onEdit}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFFEDEDED), Color(0xFFF5F5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.grey, offset: Offset(6, 6), blurRadius: 10),
          BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 10),
        ],
      ),
      child: ListTile(
        leading: icon != null
            ? Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [
              Colors.pinkAccent.shade200,
              Colors.pinkAccent.shade200
            ],),          ),
          child: Icon(icon, color: Colors.white),
        )
            : null,
        title: Text(title),
        subtitle: Text(value),
        trailing: IconButton(icon:  Icon(Icons.edit, color:AppTheme.patientIcon), onPressed: onEdit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFEDEDED),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : patientData == null
          ? const Center(child: Text('Failed to load profile'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Colors.pinkAccent.shade200,
                    Colors.pinkAccent.shade200
                  ],
                  begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.pinkAccent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.person, size: 70, color: Colors.white),
              ),
              const SizedBox(height: 20),
              profileCard(
                title: "Name",
                value: "${patientData!['first_name']} ${patientData!['last_name']}",
                icon: Icons.person,
                onEdit: () => _updateField("name", patientData!['first_name'], secondField: "last_name", secondValue: patientData!['last_name']),
              ),
              profileCard(title: "Email", value: patientData!['email'], icon: Icons.mail, onEdit: () => _updateField("email", patientData!['email'])),
              // profileCard(title: "Username", value: patientData!['username'], icon: Icons.person, onEdit: () => _updateField("username", patientData!['username'])),
              profileCard(title: "Phone", value: patientData!['phone_number'], icon: Icons.phone, onEdit: () => _updateField("phone_number", patientData!['phone_number'])),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.patientAppbar,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon:  Icon(Icons.logout, color: Colors.white),
                label:  Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      // 🔹 Edit Modal
      floatingActionButton: isEditing
          ? FloatingActionButton(
        backgroundColor: Colors.white.withOpacity(0.9),
        onPressed: () {},
        child: Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Edit ${editingField == 'name' ? 'Name' : editingField}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                neumorphicInput(label: editingField == 'name' ? 'First Name' : editingField, controller: controller1, icon: Icons.person),
                if (editingField == 'name')
                  neumorphicInput(label: 'Last Name', controller: controller2, icon: Icons.person),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: ElevatedButton(onPressed: () => setState(() => isEditing = false), child: const Text("Cancel"))),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(onPressed: _saveField, child: const Text("Save"))),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
          : null,
    );
  }
}
