import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart' show WebSocketChannel;
import '../../core/config/app_config.dart';
import '../patient/PatientDoctorProfile_OR_ChatDoctorProfile.dart' hide baseUrl;
import 'ChatPatientProfile.dart' hide baseUrl;
class ChatPage extends StatefulWidget {
  final String name;
  final String userId;
  final String otherId;
  final String token;
  final String? profileImageUrl;

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
  late WebSocketChannel channel;
  String _role = ""; // doctor أو patient


  // final Color senderColor = Color(0xFFF9A8D4);   // زهري فاتح (sender_id)
  // final Color receiverColor = Color(0xFFEC4899); // زهري غامق (receiver_id)
  // لون الرسائل المرسلة (أنا) → زهري
  final LinearGradient senderColor = const LinearGradient(
    colors: [
      Colors.white,
      Colors.white,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

// لون الرسائل المستقبَلة → أبيض
  final LinearGradient receiverColor = const LinearGradient(
    colors: [
      Colors.white,
      Colors.white,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


  @override
  void initState() {
    super.initState();
    _loadRole();

    fetchOldMessages();

    channel = WebSocketChannel.connect(
      Uri.parse("$wsUrl?token=${widget.token}"),
    );

    channel.stream.listen((event) {
      final data = json.decode(event);
      setState(() {
        messages.add({
          "isSender": data["sender_id"] == widget.userId,
          "text": data["message_text"],
          "time": data["timestamp"],
          "type": data["type"],
        });
      });
      scrollToBottom();
    });
  }
  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString("role") ?? "";
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void sendMessageWS() {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    // إذا الدكتور → نضيف Dr: قبل النص المرسل
    if (_role == "doctor") {
      text = "Dr: $text";
    }

    final payload = {
      "receiver_id": widget.otherId,
      "message": text,
      "type": "text",
    };

    channel.sink.add(json.encode(payload));
    _controller.clear();
    scrollToBottom();
  }

  DateTime parseServerTime(String time) {
    // إذا ما فيه timezone → اعتبره UTC
    if (!time.contains('Z') && !time.contains('+')) {
      time = '${time}Z';
    }
    return DateTime.parse(time).toLocal();
  }


  void scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }
  Future<void> fetchOldMessages() async {
    try {
      final url = chatMessages + widget.otherId;
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        setState(() {
          messages = data.map((msg) {
            final senderId = msg["sender_id"].toString().trim();
            final isSender = senderId == widget.userId.trim();

            return {
              "isSender": isSender,
              "text": msg["message_text"] ?? "",
              "time": msg["timestamp"] ?? DateTime.now().toIso8601String(),
              "type": msg["type"] ?? "text",
            };
          }).toList();
        });

        scrollToBottom();
      } else {
        print("Failed to fetch messages: ${response.statusCode}");
        print("Body: ${response.body}");
      }
    } catch (e) {
      print("❌ Fetch old messages error: $e");
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
                    Border(bottom: BorderSide(color: Colors.white38)),
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
                              ? NetworkImage("$baseUrl$imageUrl")
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
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isImage = msg["type"] == "image";

                    String formattedTime = "";
                    try {
                      formattedTime = DateFormat('hh:mm a')
                          .format(parseServerTime(msg["time"]));

                    } catch (e) {
                      formattedTime = "";
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.centerLeft, // كل الرسائل على اليسار
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        constraints: const BoxConstraints(
                          maxWidth: 220,
                          minWidth: 100,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF472B6), // نفس اللون لكل الرسائل (زهري)
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF472B6).withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isImage
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            baseUrl + msg["text"],
                            width: 150,
                          ),
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg["text"],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                formattedTime,
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 9,
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
                        decoration: InputDecoration(
                          prefixText: _role == "doctor" ? "Dr: " : null, // إذا دور الدكتور → Dr: ثابت
                          hintText: "Write ...",
                          border: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: 5,
                      ),
                    ),

                    IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.pinkAccent),
                          onPressed: sendMessageWS,
                        )


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
