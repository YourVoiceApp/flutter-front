import 'package:flutter/material.dart';

/// 열품타 느낌: 여백·단순·부드러운 회색 바탕, 포인트 컬러 최소 사용
class YeolpumtaTheme {
  YeolpumtaTheme._();

  static const Color bg = Color(0xFFF2F3F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color accent = Color(0xFF5856D6);
  static const Color accentSoft = Color(0xFFE8E7FA);
  static const Color divider = Color(0xFFE5E5EA);

  /// System fonts for Hangul when Roboto has no glyphs (typical on Windows).
  static const List<String> _koreanFallbackFonts = [
    'Malgun Gothic',
    'Apple SD Gothic Neo',
    'Noto Sans CJK KR',
    'Noto Sans KR',
  ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      fontFamilyFallback: _koreanFallbackFonts,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 64,
        indicatorColor: accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? accent : textSecondary,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: divider, width: 0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 0.5),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
