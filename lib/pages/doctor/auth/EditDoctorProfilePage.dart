import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:university_project/pages/password/pass_doctor/PassDoctorVerifyOtpPage.dart';


const baseUrl = "http://10.0.2.2:8000/";

class EditDoctorProfilePage extends StatefulWidget {
  final Map<String, dynamic> doctorData;
  final String token;

  const EditDoctorProfilePage({
    Key? key,
    required this.doctorData,
    required this.token,
  }) : super(key: key);

  @override
  State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
}

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
  Map<String, TextEditingController> _controllers = {};
  Map<String, bool> _isEditing = {};
  File? _selectedImage;

  final List<String> _genders = ['male', 'female', 'other'];
  final List<String> _specializations = [
    'Breast Cancer ',

    '--'
  ];

  @override
  void initState() {
    super.initState();
    _controllers = {
      'first_name':
          TextEditingController(text: widget.doctorData['first_name']),
      'last_name': TextEditingController(text: widget.doctorData['last_name']),
      'email': TextEditingController(text: widget.doctorData['email']),
      'phone_number':
          TextEditingController(text: widget.doctorData['phone_number']),
      'specialization':
          TextEditingController(text: widget.doctorData['specialization']),
      'bio': TextEditingController(text: widget.doctorData['bio']),
      'location': TextEditingController(text: widget.doctorData['location']),
      'gender': TextEditingController(text: widget.doctorData['gender']),
      'years_of_experience': TextEditingController(
          text: widget.doctorData['years_of_experience']?.toString() ?? '0'),
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
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    final url = Uri.parse("${baseUrl}doctors/update");
    final request = http.MultipartRequest('PUT', url);

    request.headers['Authorization'] = 'Bearer ${widget.token}';

    final mimeType = lookupMimeType(_selectedImage!.path) ?? 'image/jpeg';
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_image',
        _selectedImage!.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      setState(() {
        widget.doctorData['profile_image_url'] = _selectedImage!.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile image updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update image"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✔️ تحديث حقل واحد فقط
  Future<void> _saveOneField(String field) async {
    final url = Uri.parse("${baseUrl}doctors/update");
    final request = http.MultipartRequest('PUT', url);

    request.headers['Authorization'] = 'Bearer ${widget.token}';

    // فقط الحقل الحالي
    request.fields[field] = _controllers[field]!.text;

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      setState(() {
        widget.doctorData[field] = _controllers[field]!.text;
        _isEditing[field] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$field updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update $field"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildField(String label, String field) {

    if (field == 'years_of_experience') {
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
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // يسمح بالأرقام فقط
                    LengthLimitingTextInputFormatter(2), // خبرة بحد أقصى رقمين
                  ],
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: '0',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  final value = _controllers[field]!.text;
                  if (value.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter experience in years')),
                    );
                    return;
                  }
                  // كل شيء صحيح → حفظ
                  _saveOneField(field);
                },
              ),
            ],
          )
              : ListTile(
            title: Text(label),
            subtitle: Text(widget.doctorData[field]?.toString() ?? 'Not added'),
            trailing: IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => _toggleEdit(field),
            ),
          ),
        ),
      );
    }









    if (field == 'phone_number') {
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
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: '07xxxxxxxx',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  final value = _controllers[field]!.text;
                  if (value.length != 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Phone number must be 10 digits')),
                    );
                    return;
                  }
                  if (!value.startsWith('07')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Phone number must start with 07')),
                    );
                    return;
                  }
                  // لو كل شيء صحيح → حفظ
                  _saveOneField(field);
                },
              ),
            ],
          )
              : ListTile(
            title: Text(label),
            subtitle: Text(widget.doctorData[field]?.toString() ?? 'Not added'),
            trailing: IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => _toggleEdit(field),
            ),
          ),
        ),
      );
    }



    // الحقول الخاصة Dropdown
    if (field == 'gender' || field == 'specialization') {
      final options = field == 'gender' ? _genders : _specializations;
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _isEditing[field] == true
              ? Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value:
                            _specializations.contains(_controllers[field]!.text)
                                ? _controllers[field]!.text
                                : null,
                        items: options
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          _controllers[field]?.text = val ?? '';
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _saveOneField(field),
                    ),
                  ],
                )
              : ListTile(
                  title: Text(label),
                  subtitle:
                      Text(widget.doctorData[field]?.toString() ?? 'Not added'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _toggleEdit(field),
                  ),
                ),
        ),
      );
    }

    // باقي الحقول العادية TextField
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
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _saveOneField(field),
                  ),
                ],
              )
            : ListTile(
                title: Text(label),
                subtitle:
                    Text(widget.doctorData[field]?.toString() ?? 'Not added'),
                trailing: IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _toggleEdit(field),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // الصورة
            Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 18, color: Colors.blue),
                    ),
                  ),
                )
              ],
            ),

            SizedBox(height: 20),

            _buildField('First Name', 'first_name'),
            _buildField('Last Name', 'last_name'),
            _buildField('Phone Number', 'phone_number'),
            _buildField('Specialization', 'specialization'),
            _buildField('Bio', 'bio'),
            _buildField('Location', 'location'),
            _buildField('Gender', 'gender'),
            _buildField('Experience (Years)', 'years_of_experience'),


            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: const Text("Change Password"),
                trailing: const Icon(Icons.lock_outline, color: Colors.blue),
                onTap: () async {
                  final email = widget.doctorData['email'];

                  // 1️⃣ إظهار Loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // 2️⃣ طلب إرسال OTP
                    final response = await http.post(
                      Uri.parse('${baseUrl}doctors/send-otp'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'email': email}),
                    );

                    Navigator.pop(context); // إزالة الـ loading

                    if (response.statusCode == 200) {
                      // 3️⃣ فتح صفحة التحقق من OTP مباشرة
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Passdoctorverifyotppage(
                            email: email,
                            fromProfile: true,
                          ),
                        ),
                      );
                    } else {
                      final data = jsonDecode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(data['detail'] ?? 'Failed to send OTP')),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Connection error')),
                    );
                  }
                },
              ),
            )

          ],
        ),
      ),
    );
  }
}
