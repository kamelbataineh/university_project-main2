import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  Widget build(BuildContext context) {
    return  Center(
      child: Text(
        'No messages at the moment',
        style: TextStyle(fontSize: 16, foreground: Paint()..shader = LinearGradient(
          colors: [Colors.black, Colors.pinkAccent.shade200],
        ).createShader(Rect.fromLTWH(0, 0, 200, 50)),fontWeight: FontWeight.w500),
      ),
    );
  }
}
