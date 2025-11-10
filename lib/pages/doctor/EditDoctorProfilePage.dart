import 'package:flutter/material.dart';

class EditDoctorProfilePage extends StatefulWidget {
  final Map<String, dynamic> doctorData;

  const EditDoctorProfilePage({Key? key, required this.doctorData})
      : super(key: key);

  @override
  State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
}

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _specialization;
  late TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.doctorData['first_name']);
    _lastName = TextEditingController(text: widget.doctorData['last_name']);
    _email = TextEditingController(text: widget.doctorData['email']);
    _specialization =
        TextEditingController(text: widget.doctorData['specialization']);
    _phone = TextEditingController(text: widget.doctorData['phone_number']);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _specialization.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Profile updated successfully ✅'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField('First Name', _firstName),
            const SizedBox(height: 10),
            _buildTextField('Last Name', _lastName),
            const SizedBox(height: 10),
            _buildTextField('Email', _email),
            const SizedBox(height: 10),
            _buildTextField('Specialization', _specialization),
            const SizedBox(height: 10),
            _buildTextField('Phone Number', _phone),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
