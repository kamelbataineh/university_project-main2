import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFont {
  static TextStyle regular({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.black,
  }) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }
}
