import 'package:flutter/material.dart';

/// 간단(Gandan) 앱 느낌: 연회색 캔버스 위 흰 카드, 에메랄드 포인트.
class YeolpumtaTheme {
  YeolpumtaTheme._();

  /// 화면 전체 바탕 (순백보다 한 단계 어두운 회색 — 카드와 구분)
  static const Color bg = Color(0xFFF2F4F7);

  /// 카드·목록 행·바텀시트 (흰 패널)
  static const Color surface = Color(0xFFFFFFFF);

  /// 아이콘 원형 배경 등 (중립 틴트)
  static const Color iconMutedBg = Color(0xFFF1F5F9);

  /// 리스트 행·카드 테두리 (명확한 구분용)
  static const Color outline = Color(0xFFE2E5EB);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF9CA3AF);

  /// 메인 액션·포인트 (에메랄드 — green-600보다 한 톤 부드럽게)
  static const Color accent = Color(0xFF10B981);

  /// 보조 하이라이트
  static const Color accentLight = Color(0xFF6EE7B7);

  /// 배경 틴트·칩·네비 인디케이터
  static const Color accentSoft = Color(0xFFD1FAE5);

  static const Color divider = Color(0xFFE8EAEE);

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
      primary: accent,
      onPrimary: Colors.white,
      secondary: accentLight,
      onSecondary: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      fontFamilyFallback: _koreanFallbackFonts,
      splashColor: accent.withValues(alpha: 0.08),
      highlightColor: accent.withValues(alpha: 0.06),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
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
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outline, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(color: divider.withValues(alpha: 0.9), thickness: 1),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: divider,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: outline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
