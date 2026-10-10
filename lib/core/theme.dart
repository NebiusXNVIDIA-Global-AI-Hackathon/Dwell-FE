import 'package:material_ui/material_ui.dart';

abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
}

// seed 하나로 라이트/다크 팔레트 전체 생성(앱 전체 테마 색상 만드는 기준색)
const _seedColor = Color(0xFF243B53);

ThemeData buildTheme(Brightness brightness) {
  final theme = ThemeData(
    fontFamily: 'Pretendard Variable',
    //아래는 페이지 배경색 따로 설정
    scaffoldBackgroundColor: brightness == Brightness.light
        ? const Color(0xFFF8F8F8)
        : null,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ),
  );
  // Clear added tracking in both styles and locale geometry. copyWith(null)
  // would retain spacing, and locale merging could otherwise restore it.
  return theme.copyWith(
    textTheme: _fontSpacingTheme(theme.textTheme),
    primaryTextTheme: _fontSpacingTheme(theme.primaryTextTheme),
    typography: theme.typography.copyWith(
      black: _fontSpacingTheme(theme.typography.black),
      white: _fontSpacingTheme(theme.typography.white),
      englishLike: _fontSpacingTheme(theme.typography.englishLike),
      dense: _fontSpacingTheme(theme.typography.dense),
      tall: _fontSpacingTheme(theme.typography.tall),
    ),
  );
}

TextTheme _fontSpacingTheme(TextTheme theme) => TextTheme(
  displayLarge: _fontSpacingStyle(theme.displayLarge),
  displayMedium: _fontSpacingStyle(theme.displayMedium),
  displaySmall: _fontSpacingStyle(theme.displaySmall),
  headlineLarge: _fontSpacingStyle(theme.headlineLarge),
  headlineMedium: _fontSpacingStyle(theme.headlineMedium),
  headlineSmall: _fontSpacingStyle(theme.headlineSmall),
  titleLarge: _fontSpacingStyle(theme.titleLarge),
  titleMedium: _fontSpacingStyle(theme.titleMedium),
  titleSmall: _fontSpacingStyle(theme.titleSmall),
  bodyLarge: _fontSpacingStyle(theme.bodyLarge),
  bodyMedium: _fontSpacingStyle(theme.bodyMedium),
  bodySmall: _fontSpacingStyle(theme.bodySmall),
  labelLarge: _fontSpacingStyle(theme.labelLarge),
  labelMedium: _fontSpacingStyle(theme.labelMedium),
  labelSmall: _fontSpacingStyle(theme.labelSmall),
);

// TextStyle.copyWith cannot remove a nullable property. Preserve every other
// public style attribute, omitting letterSpacing so the font supplies spacing.
TextStyle? _fontSpacingStyle(TextStyle? style) => style == null
    ? null
    : TextStyle(
        inherit: style.inherit,
        color: style.color,
        backgroundColor: style.backgroundColor,
        fontFamily: style.fontFamily,
        fontFamilyFallback: style.fontFamilyFallback,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
        wordSpacing: style.wordSpacing,
        textBaseline: style.textBaseline,
        height: style.height,
        leadingDistribution: style.leadingDistribution,
        locale: style.locale,
        foreground: style.foreground,
        background: style.background,
        shadows: style.shadows,
        fontFeatures: style.fontFeatures,
        fontVariations: style.fontVariations,
        decoration: style.decoration,
        decorationColor: style.decorationColor,
        decorationStyle: style.decorationStyle,
        decorationThickness: style.decorationThickness,
        debugLabel: style.debugLabel,
        overflow: style.overflow,
      );
