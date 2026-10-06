import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
}

// seed 하나로 라이트/다크 팔레트 전체 생성
const _seedColor = Color(0xFF2F6F5E);

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ),
  );
}
