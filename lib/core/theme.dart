import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF0D2742);
  static const Color navy2 = Color(0xFF1B3B5F);
  static const Color teal = Color(0xFF16B9A6);
  static const Color tealSoft = Color(0xFFE5F8F5);
  static const Color red = Color(0xFFD92D49);
  static const Color redSoft = Color(0xFFFFE9EE);
  static const Color purpleSoft = Color(0xFFEDEBFF);
  static const Color yellowSoft = Color(0xFFFFF2DF);
  static const Color pageBg = Color(0xFFEFF4F8);
  static const Color bg = pageBg;
  static const Color muted = Color(0xFF6E849B);
  static const Color border = Color(0xFFE0E7ED);
  static const Color blue = Color(0xFF2F80ED);
  static const Color slate = Color(0xFF6F8093);
  static const Color paleBlue = Color(0xFFEAF3FF);
  static const Color card = Colors.white;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBg,
        colorScheme: ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.light),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: teal, width: 1.5)),
        ),
      );
}
