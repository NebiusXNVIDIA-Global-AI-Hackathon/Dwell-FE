/// 영어 + 모국어 한 쌍 — 서버가 번역을 같이 내려준다
class LocalizedText {
  final String en;

  /// 번역이 아직 없으면 null
  final String? native;

  const LocalizedText(this.en, [this.native]);

  /// 모국어 우선, 없으면 영어
  String resolve({bool preferNative = false}) =>
      preferNative ? (native ?? en) : en;
}
