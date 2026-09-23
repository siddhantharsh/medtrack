import 'package:flutter/material.dart';
import '../models/models.dart';

/// MedTrack design tokens — all colors, radii, and text styles in one place.
class AppTheme {
  AppTheme._();

  static const teal = Color(0xFF028090);
  static const mint = Color(0xFF02C39A);
  static const amber = Color(0xFFFFB347);
  static const background = Color(0xFFF5F9F8);
  static const nearBlack = Color(0xFF16262B);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const missed = Color(0xFFE53935);
  static const dispensed = Color(0xFF1E88E5);
  static const cardRadius = 13.0;

  static Color statusColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.pending:
        return amber;
      case DoseStatus.dispensed:
        return dispensed;
      case DoseStatus.collected:
        return mint;
      case DoseStatus.missed:
        return missed;
    }
  }

  static Color statusTextColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.pending:
        return const Color(0xFF7A5000);
      case DoseStatus.dispensed:
        return Colors.white;
      case DoseStatus.collected:
        return Colors.white;
      case DoseStatus.missed:
        return Colors.white;
    }
  }

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          brightness: Brightness.light,
          background: background,
          surface: surfaceWhite,
          primary: teal,
          secondary: mint,
          error: missed,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        cardTheme: CardTheme(
          color: surfaceWhite,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F7F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: teal, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surfaceWhite,
          selectedItemColor: teal,
          unselectedItemColor: Color(0xFF8AADAC),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}
