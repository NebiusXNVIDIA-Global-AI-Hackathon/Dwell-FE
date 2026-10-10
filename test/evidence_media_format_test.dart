import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dwell/features/cases/services/evidence_media_format.dart';
import 'package:dwell/features/cases/services/evidence_audio_recorder.dart';
import 'package:record/record.dart';

void main() {
  test('Browser encoder uses runtime support; mobile keeps AAC', () async {
    expect(
      await selectEvidenceAudioEncoder(
        (e) async => e == AudioEncoder.opus,
        browser: true,
      ),
      AudioEncoder.opus,
    );
    expect(
      await selectEvidenceAudioEncoder(
        (e) async => e == AudioEncoder.aacLc,
        browser: true,
      ),
      AudioEncoder.aacLc,
    );
    expect(
      await selectEvidenceAudioEncoder(
        (e) async => e == AudioEncoder.wav,
        browser: true,
      ),
      AudioEncoder.wav,
    );
    final checked = <AudioEncoder>[];
    expect(
      await selectEvidenceAudioEncoder((e) async {
        checked.add(e);
        return true;
      }, browser: false),
      AudioEncoder.aacLc,
    );
    expect(checked, [AudioEncoder.aacLc]);
    await expectLater(
      selectEvidenceAudioEncoder((_) async => false, browser: true),
      throwsUnsupportedError,
    );
  });
  test(
    'Container determines MIME and extension, never the supplied filename',
    () {
      final mp4 = Uint8List.fromList([
        0,
        0,
        0,
        24,
        ...'ftypM4A '.codeUnits,
        0,
        0,
        0,
        0,
      ]);
      expect(evidenceMediaFormat(mp4, audio: true), (
        mime: 'audio/mp4',
        extension: 'm4a',
      ));
      final webm = Uint8List.fromList([
        0x1a,
        0x45,
        0xdf,
        0xa3,
        ...List.filled(20, 0),
      ]);
      expect(evidenceMediaFormat(webm, audio: false), (
        mime: 'video/webm',
        extension: 'webm',
      ));
      expect(evidenceMediaFormat(webm, audio: true), (
        mime: 'audio/webm',
        extension: 'webm',
      ));
      final wav = Uint8List.fromList([
        ...'RIFF'.codeUnits,
        0,
        0,
        0,
        0,
        ...'WAVE'.codeUnits,
        0,
        0,
        0,
        0,
      ]);
      expect(evidenceMediaFormat(wav, audio: true), (
        mime: 'audio/wav',
        extension: 'wav',
      ));
      expect(
        () => evidenceMediaFormat(wav, audio: false),
        throwsFormatException,
      );
      expect(
        () => evidenceMediaFormat(Uint8List(0), audio: true),
        throwsFormatException,
      );
      expect(
        () => evidenceMediaFormat(Uint8List(40), audio: true),
        throwsFormatException,
      );
    },
  );
  test(
    'Streaming WebM gains decoder duration without changing media payload',
    () {
      final source = Uint8List.fromList([
        0x1a,
        0x45,
        0xdf,
        0xa3,
        0x80,
        0x18,
        0x53,
        0x80,
        0x67,
        0xff,
        0x15,
        0x49,
        0xa9,
        0x66,
        0x87,
        0x2a,
        0xd7,
        0xb1,
        0x83,
        0x0f,
        0x42,
        0x40,
        0x1f,
        0x43,
        0xb6,
        0x75,
        0x83,
        1,
        2,
        3,
      ]);
      final patched = withWebmDuration(source, 6.25);
      expect(patched.length, source.length + 11);
      expect(patched[14], 0x92);
      expect(ByteData.sublistView(patched, 25, 33).getFloat64(0), 6250);
      expect(patched.sublist(33), source.sublist(22));
      expect(withWebmDuration(patched, 9), same(patched));
      expect(() => withWebmDuration(source, double.nan), throwsFormatException);
      expect(
        () => withWebmDuration(Uint8List.fromList([0]), 6),
        throwsFormatException,
      );
      final finite = Uint8List.fromList(source)..[9] = 0x97;
      expect(() => withWebmDuration(finite, 6), throwsFormatException);
    },
  );
}
