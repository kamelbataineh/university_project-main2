import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/config/app_font.dart';

class YoutubeVideoPage extends StatefulWidget {
  const YoutubeVideoPage({super.key});

  @override
  State<YoutubeVideoPage> createState() => _YoutubeVideoPageState();
}

class _YoutubeVideoPageState extends State<YoutubeVideoPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    InAppWebViewController.setWebContentsDebuggingEnabled(true);

    _controller = YoutubePlayerController(
      initialVideoId: '9p0RpbkWqnc',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false, // تأكد أنه غير مكتوم
        enableCaption: true,
        forceHD: true,
      ),
    );

    // رفع الصوت بعد التهيئة (0 إلى 100)
    _controller.setVolume(100);
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.pink,
        progressColors: const ProgressBarColors(
          playedColor: Colors.pink,
          handleColor: Colors.pinkAccent,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9F7FC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.pink.shade400,
            centerTitle: true,
            title: Text(
              'Breast Cancer Awareness',
              style: AppFont.regular(
                size: 20,
                weight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // 🎬 Video Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: player,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 🩺 Title
                  const Text(
                    'Early Detection Saves Lives',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 📄 Description
                  const Text(
                    'This educational video explains the importance of early '
                        'breast cancer screening, warning signs, and how regular '
                        'checkups can help save lives. We encourage all patients '
                        'to stay informed and proactive.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 🎀 Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.pink.shade100),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.favorite, color: Colors.pink),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Regular screening and awareness play a vital role '
                                'in early diagnosis and effective treatment.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
