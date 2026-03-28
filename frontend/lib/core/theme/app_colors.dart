import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Professional AgriTech Color Palette for AI Crop Doctor
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY BRAND COLORS
  // ============================================
  static const Color primary = Color(0xFF2E7D32);      // Deep Green
  static const Color primaryLight = Color(0xFF66BB6A); // Light Green
  static const Color accent = Color(0xFFFFC107);       // Warning/Highlight Accent
  static const Color background = Color(0xFFF4F7F6);   // Clean Background
  static const Color surface = Colors.white;

  // ============================================
  // NATURE & EARTH PALETTES
  // ============================================
  static const Color forest800 = Color(0xFF1B5E20);
  static const Color forest600 = Color(0xFF2E7D32);
  static const Color forest400 = Color(0xFF4CAF50);
  static const Color forest100 = Color(0xFFE8F5E9);
  static const Color forest50 = Color(0xFFF1F8E9); // Updated from F1F8F1
  static const Color leaf100 = Color(0xFFE8F5E9);
  static const Color nature600 = Color(0xFF16A34A); // Updated from 43A047
  static const Color nature50 = Color(0xFFFDFBF7); // Subtle tan/organic white (Updated from FDFAF2)
  
  static const Color clay800 = Color(0xFF4E342E);
  static const Color clay600 = Color(0xFF6D4C41);
  static const Color tan100 = Color(0xFFF5F5F5);
  static const Color tan50 = Color(0xFFF9F8F6); // Updated from FCFBF9
  static const Color leaf50 = Color(0xFFF0FDF4);

  // Missing color tokens used in various widgets
  static const Color red500 = error;
  static const Color red600 = Color(0xFFDC2626);
  static const Color amber500 = warning;
  static const Color amber600 = Color(0xFFD97706);
  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color nature100 = Color(0xFFDCFCE7);
  static const Color nature200 = Color(0xFFBBF7D0);
  static const Color nature500 = Color(0xFF22C55E);
  static const Color nature800 = Color(0xFF166534);
  static const Color nature900 = Color(0xFF14532D);
  static const Color primaryGreen = primary;
  static const Color secondaryGreen = Color(0xFF15803D);
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray900 = Color(0xFF111827);
  static const Color earth500 = Color(0xFF78350F);
  static const Color verified = success;

  // ============================================
  // STATUS COLORS
  // ============================================
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF44474E);
  static const Color textHint = Color(0xFF74777F);

  // ============================================
  // NEUTRAL COLORS
  // ============================================
  static const Color gray100 = Color(0xFFF1F4F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);

  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber700 = Color(0xFFB45309);
  static const Color red400 = Color(0xFFF87171);

  // ============================================
  // GRADIENTS
  // ============================================
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFF1F8F5)],
  );

  // ============================================
  // SHADOWS
  // ============================================
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> smallShadow = [
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}
