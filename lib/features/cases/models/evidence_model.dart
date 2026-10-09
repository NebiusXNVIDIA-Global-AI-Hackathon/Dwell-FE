import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';

enum EvidenceType { photo }

/// Session-only photo: one original byte buffer shared by all previews.
class EvidenceModel {
  EvidenceModel._({
    required this.id,
    required this.file,
    required this.bytes,
    required this.mimeType,
    required this.addedAt,
  });
  static int _sequence = 0;
  final String id;
  final XFile file;
  final Uint8List bytes;
  final String mimeType;
  final DateTime addedAt;
  EvidenceType get type => EvidenceType.photo;
  String get fileName => file.name;

  static Future<EvidenceModel> fromCapture(XFile file) => fromFile(file);

  static Future<EvidenceModel> fromFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final String mime;
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      mime = 'image/jpeg';
    } else if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71 &&
        bytes[4] == 13 &&
        bytes[5] == 10 &&
        bytes[6] == 26 &&
        bytes[7] == 10) {
      mime = 'image/png';
    } else if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      mime = 'image/webp';
    } else {
      throw const FormatException('The file is not a supported photo.');
    }
    // Reject corrupt captures without transforming or re-encoding the original.
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
    final now = DateTime.now();
    return EvidenceModel._(
      id: '${now.microsecondsSinceEpoch}-${++_sequence}',
      file: file,
      bytes: bytes,
      mimeType: mime,
      addedAt: now,
    );
  }
}
