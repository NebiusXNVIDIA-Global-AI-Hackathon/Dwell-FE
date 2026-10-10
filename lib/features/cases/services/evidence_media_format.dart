import 'dart:typed_data';

({String mime, String extension}) evidenceMediaFormat(
  Uint8List bytes, {
  required bool audio,
}) {
  if (bytes.length <= 12) {
    throw const FormatException('Empty or incomplete recording.');
  }
  if (bytes[0] == 0x1a &&
      bytes[1] == 0x45 &&
      bytes[2] == 0xdf &&
      bytes[3] == 0xa3) {
    return (mime: audio ? 'audio/webm' : 'video/webm', extension: 'webm');
  }
  if (String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
    final mov = String.fromCharCodes(bytes.sublist(8, 12)) == 'qt  ';
    return (
      mime: audio
          ? 'audio/mp4'
          : mov
          ? 'video/quicktime'
          : 'video/mp4',
      extension: audio
          ? 'm4a'
          : mov
          ? 'mov'
          : 'mp4',
    );
  }
  if (audio &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE') {
    return (mime: 'audio/wav', extension: 'wav');
  }
  throw const FormatException('Unsupported recording container.');
}

// Only streaming WebM with an unknown-sized Segment may grow its Info block.
// Existing finite files are left untouched; no media samples are re-encoded.
Uint8List withWebmDuration(Uint8List bytes, double seconds) {
  if (!seconds.isFinite || seconds <= 0) {
    throw const FormatException('Invalid media duration.');
  }
  ({int value, int length, bool unknown}) read(int offset, {bool id = false}) {
    if (offset >= bytes.length) throw const FormatException('Truncated WebM.');
    var mask = 0x80;
    var length = 1;
    while (mask > 0 && (bytes[offset] & mask) == 0) {
      mask >>= 1;
      length++;
    }
    if (mask == 0 || offset + length > bytes.length) {
      throw const FormatException('Invalid WebM element.');
    }
    var value = id ? bytes[offset] : bytes[offset] & (mask - 1);
    var unknown = (bytes[offset] & (mask - 1)) == mask - 1;
    for (var i = 1; i < length; i++) {
      value = value * 256 + bytes[offset + i];
      unknown = unknown && bytes[offset + i] == 255;
    }
    return (value: value, length: length, unknown: !id && unknown);
  }

  var offset = 0;
  while (offset < bytes.length) {
    final id = read(offset, id: true);
    offset += id.length;
    final size = read(offset);
    offset += size.length;
    if (id.value == 0x18538067) {
      final streaming = size.unknown;
      final end = streaming ? bytes.length : offset + size.value;
      while (offset < end) {
        final child = read(offset, id: true);
        offset += child.length;
        final sizeOffset = offset;
        final childSize = read(offset);
        offset += childSize.length;
        if (child.value == 0x1549a966) {
          final infoEnd = offset + childSize.value;
          if (childSize.unknown || infoEnd > bytes.length) {
            throw const FormatException('Truncated WebM metadata.');
          }
          var cursor = offset;
          var scale = 1000000;
          while (cursor < infoEnd) {
            final field = read(cursor, id: true);
            cursor += field.length;
            final fieldSize = read(cursor);
            cursor += fieldSize.length;
            if (fieldSize.unknown || cursor + fieldSize.value > infoEnd) {
              throw const FormatException('Truncated WebM metadata field.');
            }
            if (field.value == 0x4489) return bytes;
            if (field.value == 0x2ad7b1) {
              scale = 0;
              for (var i = 0; i < fieldSize.value; i++) {
                scale = scale * 256 + bytes[cursor + i];
              }
            }
            cursor += fieldSize.value;
          }
          if (!streaming || scale <= 0 || infoEnd > bytes.length) {
            throw const FormatException('WebM duration metadata unavailable.');
          }
          final duration = ByteData(11)
            ..setUint8(0, 0x44)
            ..setUint8(1, 0x89)
            ..setUint8(2, 0x88)
            ..setFloat64(3, seconds * 1e9 / scale);
          final result = Uint8List(bytes.length + 11)
            ..setRange(0, infoEnd, bytes)
            ..setRange(infoEnd, infoEnd + 11, duration.buffer.asUint8List())
            ..setRange(infoEnd + 11, bytes.length + 11, bytes, infoEnd);
          var newSize = childSize.value + 11;
          if (newSize >= (1 << (7 * childSize.length)) - 1) {
            throw const FormatException('WebM metadata size overflow.');
          }
          for (var i = childSize.length - 1; i >= 0; i--) {
            result[sizeOffset + i] = newSize & 255;
            newSize >>= 8;
          }
          result[sizeOffset] |= 1 << (8 - childSize.length);
          return result;
        }
        if (childSize.unknown) break;
        offset += childSize.value;
      }
      break;
    }
    if (size.unknown) break;
    offset += size.value;
  }
  throw const FormatException('WebM metadata unavailable.');
}
