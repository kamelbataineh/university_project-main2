import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../components/chat_page.dart';

const baseUrl = "http://10.0.2.2:8000/";

class ChatsListPage extends StatefulWidget {
  final String userId;
  final String token;

  const ChatsListPage({required this.userId, required this.token, Key? key}) : super(key: key);

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  List<Map<String, dynamic>> chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    try {
      print("Sending token: ${widget.token}");
      final response = await http.get(
        Uri.parse(chatList),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          chats = data.map((e) => e as Map<String, dynamic>).toList();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
         child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : chats.isEmpty
              ? const Center(child: Text('No chats available'))
              : ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              // جلب الاسم الكامل أو الاسم المعروض
              final name = chat["chat_with"] ?? "Unknown";
              // جلب رابط الصورة إذا موجود
              final imageUrl = chat["profile_image_url"] ?? "";
              final lastMessage = chat["lastMessage"] ?? "";

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
                        profileImageUrl: imageUrl, // تمرير رابط الصورة
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                            Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chat_bubble_outline,
                          color: Colors.pink.shade300),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    );
  }
}
