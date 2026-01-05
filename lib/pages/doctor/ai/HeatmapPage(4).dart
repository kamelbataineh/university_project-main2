import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class HeatmapPage extends StatelessWidget {
  final String overlayB64;
  final String heatmapB64;
  final String imageName;

  const HeatmapPage({
    super.key,
    required this.overlayB64,
    required this.heatmapB64,
    required this.imageName,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List overlayBytes = overlayB64.isNotEmpty ? base64Decode(overlayB64) : Uint8List(0);
    Uint8List heatmapBytes = heatmapB64.isNotEmpty ? base64Decode(heatmapB64) : Uint8List(0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Heatmaps - $imageName"),
        backgroundColor: Colors.indigo.shade400,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Overlay Image",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            overlayBytes.isEmpty
                ? Center(child: Text("Overlay image not available"))
                : Image.memory(overlayBytes),
            const SizedBox(height: 16),
            const Text(
              "Grad-CAM Heatmap",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            heatmapBytes.isEmpty
                ? Center(child: Text("Heatmap not available"))
                : Image.memory(heatmapBytes),          ],
        ),
      ),
    );
  }
}
