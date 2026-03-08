import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Deep emerald color palette matching the React glassmorphism design.
class AppColors {
  AppColors._();

  static const Color deepEmerald = Color(0xFF064E3B);
  static const Color darkerEmerald = Color(0xFF022C22);
  static const Color slateBlue = Color(0xFF0F172A);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber400 = Color(0xFFFBBF24);

  // Glass surface colors
  static const Color glassFill = Color(0x66064E3B); // 40% opacity
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white
  static const Color glassButtonFill = Color(0x08FFFFFF); // 3% white
  static const Color glassButtonBorder = Color(0x0DFFFFFF); // 5% white
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepEmerald,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emerald500,
        secondary: AppColors.emerald400,
        surface: AppColors.deepEmerald,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }

  /// Returns the Amiri TextStyle for Arabic / Quranic text.
  static TextStyle get quranTextStyle =>
      GoogleFonts.amiri(color: Colors.white, fontSize: 28, height: 2.2);

  /// Returns the Inter TextStyle for Latin UI text.
  static TextStyle get bodyTextStyle => GoogleFonts.inter(color: Colors.white);
}
