import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF050510); // Deep Space Blue/Black
  static const Color surface = Color(0xFF151525); // Slightly lighter for cards
  static const Color surfaceGlass = Colors.white; // Used with opacity

  // Primary Action
  static const Color primary = Color(0xFF00E5FF); // Cyan Fluorescence
  static const Color primaryDim = Color(0xFF00B8CC);
  
  // Secondary / Accents
  static const Color secondary = Color(0xFFE0E0E0);
  static const Color accentPurple = Color(0xFFD500F9);
  static const Color accentPink = Color(0xFFFF4081);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70%
  static const Color textDim = Color(0x66FFFFFF); // 40%

  // Power Zones
  static const Color zone1 = Color(0xFF808080); // Active Recovery - Grey
  static const Color zone2 = Color(0xFF3299CC); // Endurance - Blue
  static const Color zone3 = Color(0xFF00D936); // Tempo - Green
  static const Color zone4 = Color(0xFFFFD400); // Threshold - Yellow
  static const Color zone5 = Color(0xFFFF7F00); // VO2Max - Orange
  static const Color zone6 = Color(0xFFFF0000); // Anaerobic - Red
  static const Color zone7 = Color(0xFF8000FF); // Neuromuscular - Purple

  // Status
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFC400);
  static const Color error = Color(0xFFFF3D00);
  static const Color errorDark = Color(0xFFCC2E00);
  static const Color info = Color(0xFF2979FF);
  
  // Additional
  static const Color border = Color(0x33FFFFFF); // 20% opacity
  static const Color textTertiary = Color(0x4DFFFFFF); // 30% opacity
  static const Color surfaceElevated = Color(0xFF1F1F2E);
}
