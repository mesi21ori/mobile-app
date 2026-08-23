import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const seed = Color(0xFF3B82F6);
  static const blue = Color(0xFF4C9AFF);
  static const blueSoft = Color(0xFFD6E8FF);
  static const mist = Color(0xFFF4F8FF);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const gold = Color(0xFF3B82F6);
  static const orange = Color(0xFF64748B);
  static const parchment = Color(0xFFF4F8FF);

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: seed,
      onPrimary: Colors.white,
      secondary: blue,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: ink,
      outline: Color(0xFFC9DCF8),
    );
    final text = GoogleFonts.notoSansEthiopicTextTheme().apply(
      bodyColor: ink,
      displayColor: ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: mist,
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansEthiopic(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: seed),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE4EEFB)),
        ),
        shadowColor: seed.withValues(alpha: 0.08),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 10,
        shadowColor: seed.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: GoogleFonts.notoSansEthiopic(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.notoSansEthiopic(color: ink, fontSize: 15),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      ),
      chipTheme: ChipThemeData(
        selectedColor: blueSoft,
        backgroundColor: mist,
        labelStyle: GoogleFonts.notoSansEthiopic(color: ink, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        extendedTextStyle: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mist,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE4EEFB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: seed, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: Color(0xFFB9D4F8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28)),
        ),
      ),
    );
  }
}
