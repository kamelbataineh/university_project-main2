import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const baseUrl = "http://10.0.2.2:8000/";

class EditPatientProfilePage extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String token;

  const EditPatientProfilePage({
    Key? key,
    required this.patientData,
    required this.token,
  }) : super(key: key);

  @override
  State<EditPatientProfilePage> createState() => _EditPatientProfilePageState();
}

class _EditPatientProfilePageState extends State<EditPatientProfilePage> {
  Map<String, TextEditingController> _controllers = {};
  Map<String, bool> _isEditing = {};
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'first_name': TextEditingController(text: widget.patientData['first_name']),
      'last_name': TextEditingController(text: widget.patientData['last_name']),
      'phone_number': TextEditingController(text: widget.patientData['phone_number']),
    };
    _controllers.keys.forEach((key) => _isEditing[key] = false);
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _toggleEdit(String field) {
    setState(() {
      _isEditing[field] = !(_isEditing[field] ?? false);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Token is missing, please login again"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse("${baseUrl}patients/update");
    final request = http.MultipartRequest('PUT', url);

    request.headers['Authorization'] = 'Bearer ${widget.token}';
    print("Uploading image with token: ${widget.token}");

    final mimeType = lookupMimeType(_selectedImage!.path) ?? 'image/jpeg';
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_image',
        _selectedImage!.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final respJson = json.decode(respStr);

        setState(() {
          widget.patientData['profile_image_url'] = respJson['profile_image_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile image updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update image: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveOneField(String field) async {
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Token is missing, please login again"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse("${baseUrl}patients/update");
    final request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.fields[field] = _controllers[field]!.text;
    print("Updating $field with token: ${widget.token}");

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          widget.patientData[field] = _controllers[field]!.text;
          _isEditing[field] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$field updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unauthorized! Please login again."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update $field: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating $field: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildField(String label, String field) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _isEditing[field] == true
            ? Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controllers[field],
                decoration: InputDecoration(labelText: label),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _saveOneField(field),
            ),
          ],
        )
            : ListTile(
          title: Text(label),
          subtitle: Text(widget.patientData[field]?.toString() ?? 'Not added'),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: () => _toggleEdit(field),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage:
                  _selectedImage != null ? FileImage(_selectedImage!) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            _buildField('First Name', 'first_name'),
            _buildField('Last Name', 'last_name'),
            _buildField('Phone Number', 'phone_number'),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: const Text("Change Password"),
                trailing: const Icon(Icons.lock_outline, color: Colors.blue),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
