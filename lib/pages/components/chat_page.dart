import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../patient/PatientDoctorProfile_OR_ChatDoctorProfile.dart';
import 'ChatPatientProfile.dart';

class ChatPage extends StatefulWidget {
  final String name;
  final String userId;
  final String otherId;
  final String token;
  final String? profileImageUrl; // موجود أصلاً ✅

  const ChatPage({
    required this.name,
    required this.userId,
    required this.otherId,
    required this.token,
    this.profileImageUrl,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];

  final String baseUrl = "http://10.0.2.2:8000";
  final String baseUrl1 = "http://10.0.2.2:8000/";

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse(chatMessages + "${widget.otherId}"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        setState(() {
          messages = data.map((msg) {
            // تحويل أي ObjectId من MongoDB إلى String بطريقة آمنة
            String senderId = "";
            if (msg["sender_id"] is Map && msg["sender_id"]["\$oid"] != null) {
              senderId = msg["sender_id"]["\$oid"];
            } else {
              senderId = msg["sender_id"].toString();
            }

            bool isMe = senderId.trim() == widget.userId.trim();

            return {
              "sender": isMe ? "me" : "other",   // ← هذا يحدد اليمين أو اليسار
              "text": msg["type"] == "image" ? msg["preview"] : msg["message_text"],
              "time": msg["timestamp"],
              "type": msg["type"],
            };
          }).toList();

        });


        Future.delayed(const Duration(milliseconds: 200), () {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final payload = {
      "receiver_id": widget.otherId,
      "message": text,
      "type": "text"
    };

    try {
      final response = await http.post(
        Uri.parse(chatSend),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        setState(() {
          messages.add({
            "sender": "me",
            "text": text,
            "time": DateTime.now().toIso8601String(),
            "type": "text",
          });
          _controller.clear();
        });

        scrollToBottom();
      }
    } catch (e) {
      print("❌ Send error: $e");
    }
  }

  Future<void> pickAndSendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(chatUploadFile + "${widget.otherId}"),
      );
      request.headers["Authorization"] = "Bearer ${widget.token}";
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      try {
        var response = await request.send();
        final resBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final resData = json.decode(resBody);

          setState(() {
            messages.add({
              "sender": "me",
              "text": resData["preview"] ?? "",
              "time": DateTime.now().toIso8601String(),
              "type": resData["type"],
            });
          });

          scrollToBottom();
        }
      } catch (e) {
        print("❌ File upload error: $e");
      }
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.profileImageUrl ?? "";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF1F5), Color(0xFFF3E8FF), Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== AppBar =====
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  border:
                      const Border(bottom: BorderSide(color: Colors.white38)),
                ),
                child: GestureDetector(
                  onTap: () async {

                      final prefs = await SharedPreferences.getInstance();
                      final role = prefs.getString("role") ?? "";

                      if (role == "doctor") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPatientProfile(
                              patientId: widget.otherId, // المريض
                              userId: widget.userId, // الدكتور الحالي
                              token: widget.token,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientdoctorprofileOrChatdoctorprofile(
                              doctorId: widget.otherId, // الدكتور الآخر
                              userId: widget.userId, // المريض الحالي
                              token: widget.token,
                            ),
                          ),
                        );
                      }},
                    child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.pinkAccent),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.pink.shade300,
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage("$baseUrl1$imageUrl")
                            : null,
                        child: imageUrl.isEmpty
                            ? Text(
                          widget.name[0],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                )

              ),

              // ===== Messages List =====
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg["sender"] == "me";
                    final bool isImage = msg["type"] == "image";

                    String formattedTime = "";
                    try {
                      formattedTime = DateFormat('hh:mm a')
                          .format(DateTime.parse(msg["time"]));
                    } catch (e) {
                      formattedTime = "";
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          gradient: isMe
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFF472B6),
                                    Color(0xFFE11D48)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isMe ? null : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  baseUrl + msg["text"],
                                  width: 200,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg["text"],
                                    style: TextStyle(
                                      color:
                                          isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      formattedTime,
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.pink.shade100
                                            : Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),

              // ===== Input Field =====
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  border: const Border(top: BorderSide(color: Colors.white38)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_sharp,
                          color: Colors.purpleAccent),
                     SizedBox(width: 4),

                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "   Write ...",
                          border: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: 5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.pinkAccent),
                      onPressed: sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
