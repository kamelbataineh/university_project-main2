import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../components/chat_page.dart';

class ChatsListPage extends StatefulWidget {
  final String userId;
  final String token;

  const ChatsListPage({required this.userId, required this.token, Key? key})
      : super(key: key);

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  List<Map<String, dynamic>> chats = [];
  bool isLoading = true;
  Timer? _timer;

  // خريطة لتتبع المحادثات المقروءة
  Map<String, bool> readChats = {};

  @override
  void initState() {
    super.initState();
    fetchChats();

    // تحديث كل 3 ثواني
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchChats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // جلب المحادثات من السيرفر
  Future<void> fetchChats() async {
    try {
      final response = await http.get(
        Uri.parse(chatList),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          chats = data.map((e) => e as Map<String, dynamic>).toList();

          // تعيين كل محادثة جديدة كمقروءة أو لا
          for (var chat in chats) {
            final chatId = chat["chat_with_id"].toString();
            if (!readChats.containsKey(chatId)) {
              readChats[chatId] = false; // غير مقروءة افتراضياً
            }
          }

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching chats: $e");
      setState(() => isLoading = false);
    }
  }

  // تعليم المحادثة كمقروءة بعد فتحها
  void markChatAsRead(String chatId) {
    setState(() {
      readChats[chatId] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chats.isEmpty
          ? const Center(child: Text('No chats available'))
          : ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final name = chat["chat_with"] ?? "Unknown";
          final imageUrl = chat["profile_image_url"] ?? "";

          final lastMessageRaw = chat["lastMessage"];
          final Map<String, dynamic> lastMessage =
          lastMessageRaw is Map<String, dynamic>
              ? lastMessageRaw
              : {
            "message_text":
            lastMessageRaw?.toString() ?? "",
            "sender_id": "",
            "delivered": false
          };

          final lastMessageText = lastMessage["message_text"] ?? "";
          final lastMessageSenderId = lastMessage["sender_id"] ?? "";

          // هل آخر رسالة من الطرف الثاني
          final hasNewMessageFromOther =
              lastMessageSenderId != widget.userId &&
                  readChats[chat["chat_with_id"].toString()] ==
                      false;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    name: name,
                    userId: widget.userId,
                    otherId: chat["chat_with_id"],
                    token: widget.token,
                    profileImageUrl: imageUrl,
                  ),
                ),
              ).then((_) {
                // بعد فتح الدردشة، تعليم الرسائل كمقروءة
                markChatAsRead(chat["chat_with_id"].toString());
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.shade100.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.pink.shade300,
                    backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage("$baseUrl$imageUrl")
                        : null,
                    child: imageUrl.isEmpty
                        ? Text(
                      name[0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            // النقطة الزرقاء بجانب الاسم

                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessageText,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chat_bubble,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
