import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../../core/config/app_config.dart';

class ChatPage extends StatefulWidget {
  final String name;
  final String userId;
  final String otherId;
  final String token;

  const ChatPage({
    required this.name,
    required this.userId,
    required this.otherId,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];

  final String baseUrl = "http://10.0.2.2:8000/chat";

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  // ===== Fetch messages from server =====
  Future<void> fetchMessages() async {
    print("🔹 Fetching messages...");
    try {
      final response = await http.get(
        Uri.parse(chatMessages + "${widget.otherId}"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          messages = data.map((msg) => {
            "sender": msg["sender_id"] == widget.userId ? "me" : "other",
            "text": msg["type"] == "image" ? msg["preview"] : msg["message_text"],
            "time": msg["timestamp"],
            "type": msg["type"]
          }).toList();
        });

        // Scroll to bottom
        Future.delayed(const Duration(milliseconds: 200), () {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      } else {
        print("❌ Failed to fetch messages: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching messages: $e");
    }
  }

  // ===== Send text message =====
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
            "time": DateFormat('hh:mm a').format(DateTime.now()),
            "type": "text",
          });
          _controller.clear();
        });

        Future.delayed(const Duration(milliseconds: 200), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } else {
        print("❌ Failed to send message: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }

  // ===== Pick & send file =====
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
              "time": DateFormat('hh:mm a').format(DateTime.now()),
              "type": resData["type"],
            });
          });

          Future.delayed(const Duration(milliseconds: 200), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 100,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        } else {
          print("❌ Failed to upload file: ${response.statusCode}");
        }
      } catch (e) {
        print("❌ Error uploading file: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  border: const Border(bottom: BorderSide(color: Colors.white38)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade100.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.pinkAccent),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.purpleAccent.withOpacity(0.8),
                      child: Text(
                        widget.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text("Online",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),

              // ===== Messages List =====
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg["sender"] == "me";
                    final isImage = msg["type"] == "image";

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isMe
                              ? const LinearGradient(
                            colors: [Color(0xFFF472B6), Color(0xFFE11D48)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : null,
                          color: isMe ? null : Colors.white.withOpacity(0.6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: const Offset(2, 3),
                            )
                          ],
                        ),
                        child: isImage
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            msg["text"]!,
                            width: 200,
                          ),
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg["text"]!,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.grey[800],
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                DateFormat('hh:mm a').format(DateTime.parse(msg["time"])),
                                style: TextStyle(
                                  color: isMe ? Colors.pink.shade100 : Colors.grey,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  border: const Border(top: BorderSide(color: Colors.white38)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade100.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.purpleAccent),
                      onPressed: pickAndSendFile,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: "اكتب رسالة...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          minLines: 1,
                          maxLines: 5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.pinkAccent),
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
