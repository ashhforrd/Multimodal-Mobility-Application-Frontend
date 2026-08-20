import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const primary = Color(0xFF1769E0);
  static const deepBlue = Color(0xFF0B3B8F);
  static const accent = Color(0xFF5BA8FF);
  static const success = Color(0xFF15803D);
  static const ink = Color(0xFF10233F);
  static const muted = Color(0xFF64748B);
  static const canvas = Color(0xFFF4F7FB);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Satoshi',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          primaryContainer: const Color(0xFFEAF2FF),
          onPrimaryContainer: deepBlue,
          secondaryContainer: const Color(0xFFEAF2FF),
          onSecondaryContainer: primary,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Satoshi',
            color: ink,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -.4,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 57, letterSpacing: -1.14),
          displayMedium: TextStyle(fontSize: 45, letterSpacing: -.9),
          displaySmall: TextStyle(fontSize: 36, letterSpacing: -.72),
          headlineLarge: TextStyle(
              color: ink,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -.64),
          headlineMedium: TextStyle(
              color: ink,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -.56),
          headlineSmall: TextStyle(
              color: ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -.48),
          titleLarge: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -.44),
          titleMedium: TextStyle(
              color: ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -.32),
          titleSmall: TextStyle(fontSize: 14, letterSpacing: -.28),
          bodyLarge: TextStyle(
              color: ink, fontSize: 16, height: 1.45, letterSpacing: -.32),
          bodyMedium: TextStyle(
              color: muted, fontSize: 14, height: 1.4, letterSpacing: -.28),
          bodySmall: TextStyle(fontSize: 12, letterSpacing: -.24),
          labelLarge: TextStyle(fontSize: 14, letterSpacing: -.28),
          labelMedium: TextStyle(fontSize: 12, letterSpacing: -.24),
          labelSmall: TextStyle(fontSize: 11, letterSpacing: -.22),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE5ECF5)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5ECF5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            textStyle: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );
}
