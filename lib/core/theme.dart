import 'package:google_fonts/google_fonts.dart';
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
  return ThemeData(
    //페이지 배경색 따로 설정
    scaffoldBackgroundColor: brightness == Brightness.light
        ? const Color(0xFFF8F8F8)
        : null,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ),
  );
}
