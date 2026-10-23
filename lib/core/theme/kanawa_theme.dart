// KANAWA - Design System (App Motorista)
// Cores, tipografia, espaçamento consistentes com o App Passageiro

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════
// CORES OFICIAIS KANAWA
// ═══════════════════════════════════════════════════════════
class KanawaColors {
  // Marca
  static const red = Color(0xFFE01818);
  static const redDark = Color(0xFFB91C1C);
  static const redSoft = Color(0xFFFEF2F2);

  // Azul (info, links, mapa)
  static const blue = Color(0xFF1E5FE0);
  static const blueDark = Color(0xFF0A4AD8);
  static const blueSoft = Color(0xFFE8F0FE);

  // Ciano (glow, GPS)
  static const cyan = Color(0xFF00E5FF);

  // Texto
  static const textStrong = Color(0xFF18181B);
  static const textBase = Color(0xFF3F3F46);
  static const textMuted = Color(0xFF71717A);
  static const textSubtle = Color(0xFFA1A1AA);

  // Fundos
  static const bgApp = Color(0xFFFAFAFA);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgSoft = Color(0xFFF4F4F5);
  static const bgDark = Color(0xFF0F0F12);

  // Estados
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFF0FDF4);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEF2F2);

  // Bordas
  static const border = Color(0xFFE4E4E7);
  static const borderDark = Color(0xFF27272A);

  // Motorista (destaque)
  static const driver = Color(0xFF0F766E); // teal para o motorista
  static const driverDark = Color(0xFF134E4A);
}

// ═══════════════════════════════════════════════════════════
// ESPAÇAMENTO
// ═══════════════════════════════════════════════════════════
class KanawaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

// ═══════════════════════════════════════════════════════════
// RAIOS DE BORDA
// ═══════════════════════════════════════════════════════════
class KanawaRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 999;
}

// ═══════════════════════════════════════════════════════════
// TEMA CLARO
// ═══════════════════════════════════════════════════════════
class KanawaTheme {
  static ThemeData light() {
    final base = ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: KanawaColors.bgApp,
      primaryColor: KanawaColors.red,
      colorScheme: base.colorScheme.copyWith(
        primary: KanawaColors.red,
        secondary: KanawaColors.blue,
        error: KanawaColors.danger,
        surface: KanawaColors.bgCard,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: KanawaColors.bgCard,
        elevation: 0,
        iconTheme: const IconThemeData(color: KanawaColors.textStrong),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: KanawaColors.textStrong,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KanawaColors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KanawaRadius.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KanawaColors.textMuted,
          side: const BorderSide(color: KanawaColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KanawaRadius.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KanawaColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KanawaRadius.md),
          borderSide: const BorderSide(color: KanawaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KanawaRadius.md),
          borderSide: const BorderSide(color: KanawaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KanawaRadius.md),
          borderSide: const BorderSide(color: KanawaColors.red, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KanawaRadius.md),
          borderSide: const BorderSide(color: KanawaColors.danger),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: KanawaColors.textSubtle,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: KanawaColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base
        .copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: KanawaColors.textStrong,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: KanawaColors.textStrong,
          ),
          headlineLarge: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: KanawaColors.textStrong,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: KanawaColors.textStrong,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: KanawaColors.textStrong,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: KanawaColors.textStrong,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: KanawaColors.textBase,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: KanawaColors.textBase,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: KanawaColors.textMuted,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: KanawaColors.textStrong,
          ),
        );
  }
}