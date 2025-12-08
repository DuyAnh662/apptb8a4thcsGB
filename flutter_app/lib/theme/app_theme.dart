import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Color themes matching PWA
enum AppColorTheme { blue, pink, green, purple }

// Special Event Types
enum SpecialEvent { none, tet, halloween, christmas }

class AppTheme {
  static const Map<AppColorTheme, Color> primaryColors = {
    AppColorTheme.blue: Color(0xFF4FACFE),
    AppColorTheme.pink: Color(0xFFFF4785),
    AppColorTheme.green: Color(0xFF00B894),
    AppColorTheme.purple: Color(0xFF9B59B6),
  };

  // Event Theme Colors
  static const Map<SpecialEvent, Color> eventPrimaryColors = {
    SpecialEvent.tet: Color(0xFFFFD700),
    SpecialEvent.halloween: Color(0xFFFF6B00),
    SpecialEvent.christmas: Color(0xFFFF3B3B),
    SpecialEvent.none: Color(0xFF4FACFE),
  };

  // Check for special events based on date
  static SpecialEvent getCurrentEvent() {
    final now = DateTime.now();
    final month = now.month;
    final day = now.day;

    // Tết: Jan 20 - Feb 10 (approximate Lunar New Year period)
    if ((month == 1 && day >= 20) || (month == 2 && day <= 10)) {
      return SpecialEvent.tet;
    }

    // Halloween: Oct 25 - Nov 2
    if ((month == 10 && day >= 25) || (month == 11 && day <= 2)) {
      return SpecialEvent.halloween;
    }

    // Christmas: Dec 20 - Dec 31
    if (month == 12 && day >= 20) {
      return SpecialEvent.christmas;
    }

    return SpecialEvent.none;
  }

  static ThemeData lightTheme(AppColorTheme colorTheme, {SpecialEvent? event}) {
    final primary = event != null && event != SpecialEvent.none
        ? eventPrimaryColors[event]!
        : primaryColors[colorTheme]!;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primary.withOpacity(0.8),
        surface: Colors.white.withOpacity(0.65),
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: const Color(0xFF1D1D1F),
        displayColor: const Color(0xFF1D1D1F),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1D1D1F),
        ),
      ),
    );
  }

  static ThemeData darkTheme(AppColorTheme colorTheme, {SpecialEvent? event}) {
    final primary = event != null && event != SpecialEvent.none
        ? eventPrimaryColors[event]!
        : primaryColors[colorTheme]!;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primary.withOpacity(0.8),
        surface: const Color(0xFF1E1E23).withOpacity(0.7),
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: const Color(0xFFF5F5F7),
        displayColor: const Color(0xFFF5F5F7),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFF5F5F7),
        ),
      ),
    );
  }

  // Gradient backgrounds matching PWA
  static LinearGradient getBackground(AppColorTheme theme, bool isDark, {SpecialEvent? event}) {
    // Event-specific backgrounds
    if (event != null && event != SpecialEvent.none) {
      switch (event) {
        case SpecialEvent.tet:
          return isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8E0000), Color(0xFFD32F2F)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFCDD2), Color(0xFFFFEBEE)],
                );
        case SpecialEvent.halloween:
          return isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0A2E), Color(0xFF3D1E5F)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE0B2), Color(0xFFFFF3E0)],
                );
        case SpecialEvent.christmas:
          return isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2818), Color(0xFF1B4332)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                );
        default:
          break;
      }
    }

    // Regular theme backgrounds
    if (isDark) {
      switch (theme) {
        case AppColorTheme.pink:
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D1B24), Color(0xFF451D2E)],
          );
        case AppColorTheme.green:
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2D24), Color(0xFF1D4532)],
          );
        case AppColorTheme.purple:
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF241B2D), Color(0xFF321D45)],
          );
        case AppColorTheme.blue:
        default:
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
          );
      }
    } else {
      switch (theme) {
        case AppColorTheme.pink:
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF0F6), Color(0xFFFFD6E7)],
          );
        case AppColorTheme.green:
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FFF4), Color(0xFFC6F6D5)],
          );
        case AppColorTheme.purple:
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3F0FF), Color(0xFFE9D8FD)],
          );
        case AppColorTheme.blue:
        default:
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FA), Color(0xFFE4E9F2)],
          );
      }
    }
  }

  // Get event emoji for decoration
  static List<String> getEventEmojis(SpecialEvent event) {
    switch (event) {
      case SpecialEvent.tet:
        return ['🧧', '🎆', '🏮', '🧨', '🎊', '🌸'];
      case SpecialEvent.halloween:
        return ['🎃', '👻', '🦇', '🕷️', '💀', '🕸️'];
      case SpecialEvent.christmas:
        return ['🎄', '🎅', '⛄', '🎁', '❄️', '🔔'];
      default:
        return [];
    }
  }

  // Get event title
  static String getEventTitle(SpecialEvent event) {
    switch (event) {
      case SpecialEvent.tet:
        return '🧧 Chúc Mừng Năm Mới!';
      case SpecialEvent.halloween:
        return '🎃 Happy Halloween!';
      case SpecialEvent.christmas:
        return '🎄 Merry Christmas!';
      default:
        return 'Bảng thông tin';
    }
  }
}
