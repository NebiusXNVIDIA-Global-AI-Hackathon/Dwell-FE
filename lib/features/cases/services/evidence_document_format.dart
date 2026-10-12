import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

const evidenceDocumentLimit = 10 * 1024 * 1024;
const evidenceDocumentExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];

String safeEvidenceDocumentName(String name) => name
    .replaceAll('\\', '/')
    .split('/')
    .last
    .replaceAll(RegExp(r'[\x00-\x1F\x7F\u202A-\u202E\u2066-\u2069]'), '')
    .trim();

String validateEvidenceDocument(Uint8List data, String name) {
  if (data.isEmpty) throw const FormatException('The file is empty.');
  if (data.length > evidenceDocumentLimit) {
    throw const FormatException('The file exceeds the 10 MB limit.');
  }
  final extension = name.split('.').last.toLowerCase();
  if (!evidenceDocumentExtensions.contains(extension)) {
    throw const FormatException('Choose a PDF, Word, JPG or PNG file.');
  }
  var valid = false;
  try {
    switch (extension) {
      case 'pdf':
        final head = latin1.decode(data.sublist(0, data.length.clamp(0, 1024)));
        final tail = latin1.decode(
          data.sublist((data.length - 2048).clamp(0, data.length)),
        );
        valid =
            RegExp(r'%PDF-[12]\.\d').hasMatch(head) && tail.contains('%%EOF');
      case 'doc':
        valid = _isWordCompoundFile(data);
      case 'docx':
        valid = _isWordZip(data);
      case 'jpg':
      case 'jpeg':
        valid =
            data.length >= 4 &&
            data[0] == 0xff &&
            data[1] == 0xd8 &&
            data[2] == 0xff;
      case 'png':
        valid =
            data.length >= 8 &&
            List.generate(8, (i) => data[i]).join(',') ==
                '137,80,78,71,13,10,26,10';
    }
  } catch (_) {
    valid = false;
  }
  if (!valid) {
    throw const FormatException(
      'The file content does not match its extension, or the document is unreadable.',
    );
  }
  return switch (extension) {
    'pdf' => 'application/pdf',
    'doc' => 'application/msword',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    _ =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };
}

bool _isWordZip(Uint8List data) {
  if (data.length < 4 || data[0] != 0x50 || data[1] != 0x4b) return false;
  final directory = ZipDirectory()..read(InputMemoryStream(data));
  if (directory.fileHeaders.length > 4096) return false;
  Uint8List readMember(String name, int limit) {
    final matches = directory.fileHeaders
        .where((h) => h.filename == name)
        .toList();
    if (matches.length != 1) {
      throw const FormatException('Missing Word document member.');
    }
    final header = matches.single;
    if (header.uncompressedSize > limit ||
        (header.generalPurposeBitFlag & 1) != 0) {
      throw const FormatException(
        'Word document metadata is too large or encrypted.',
      );
    }
    final raw = header.file!.getRawContent();
    final output = _LimitedDocumentOutput(limit);
    if (header.compressionMethod == 8) {
      Inflate(raw, output: output);
    } else if (header.compressionMethod == 0) {
      output.writeBytes(raw);
    } else {
      throw const FormatException('Unsupported Word ZIP compression.');
    }
    final result = output.getBytes();
    if (result.length != header.uncompressedSize ||
        getCrc32(result) != header.crc32) {
      throw const FormatException('Corrupt Word document member.');
    }
    return result;
  }

  // Only decode small XML members; bounded output also catches forged sizes.
  final contentTypes = readMember('[Content_Types].xml', 1024 * 1024);
  final documentXml = readMember('word/document.xml', 4 * 1024 * 1024);
  final typeXml = _documentXml(contentTypes);
  final wordXml = _documentXml(documentXml);
  return typeXml.contains(
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml',
      ) &&
      typeXml.contains('/word/document.xml') &&
      (wordXml.contains(
            'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
          ) ||
          wordXml.contains(
            'http://purl.oclc.org/ooxml/wordprocessingml/main',
          )) &&
      RegExp(r'<(?:\w+:)?document\b').hasMatch(wordXml);
}

String _documentXml(Uint8List bytes) {
  if (bytes.length >= 2 &&
      ((bytes[0] == 0xff && bytes[1] == 0xfe) ||
          (bytes[0] == 0xfe && bytes[1] == 0xff))) {
    if (bytes.length.isOdd) throw const FormatException('Invalid Word XML.');
    final view = ByteData.sublistView(bytes);
    final endian = bytes[0] == 0xff ? Endian.little : Endian.big;
    return String.fromCharCodes(
      List.generate(
        (bytes.length - 2) ~/ 2,
        (i) => view.getUint16(2 + i * 2, endian),
      ),
    );
  }
  return utf8.decode(bytes);
}

class _LimitedDocumentOutput extends OutputMemoryStream {
  _LimitedDocumentOutput(this.limit);
  final int limit;
  void _check(int count) {
    if (length + count > limit) {
      throw const FormatException(
        'Word metadata exceeds the safe decoding limit.',
      );
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    super.writeStream(stream);
  }
}

/// Inspect CFB directory streams, so an Excel/PowerPoint OLE file renamed
/// .doc cannot pass based solely on its common eight-byte container signature.
bool _isWordCompoundFile(Uint8List data) {
  const signature = [0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1];
  if (data.length < 512) return false;
  for (var i = 0; i < 8; i++) {
    if (data[i] != signature[i]) return false;
  }
  final view = ByteData.sublistView(data);
  if (view.getUint16(28, Endian.little) != 0xfffe) return false;
  final shift = view.getUint16(30, Endian.little);
  if (shift != 9 && shift != 12) return false;
  final sectorSize = 1 << shift;
  int sectorOffset(int sector) {
    final offset = (sector + 1) * sectorSize;
    if (sector < 0 || offset + sectorSize > data.length) {
      throw const FormatException('Truncated Word document.');
    }
    return offset;
  }

  final fat = <int>[];
  final fatCount = view.getUint32(44, Endian.little);
  // A 10 MB document needs fewer than 109 FAT sectors; extended DIFAT files
  // are outside this bounded validation path and are rejected safely.
  if (fatCount == 0 || fatCount > 109) return false;
  for (var i = 0; i < fatCount; i++) {
    final start = sectorOffset(view.getUint32(76 + i * 4, Endian.little));
    for (var j = 0; j < sectorSize; j += 4) {
      fat.add(view.getUint32(start + j, Endian.little));
    }
  }
  var directory = view.getUint32(48, Endian.little);
  final visited = <int>{};
  while (directory != 0xfffffffe) {
    if (!visited.add(directory) || directory >= fat.length) return false;
    final start = sectorOffset(directory);
    for (var entry = start; entry < start + sectorSize; entry += 128) {
      final length = view.getUint16(entry + 64, Endian.little);
      if (data[entry + 66] != 2 || length < 2 || length > 64 || length.isOdd) {
        continue;
      }
      final name = String.fromCharCodes(
        List.generate(
          length ~/ 2 - 1,
          (i) => view.getUint16(entry + i * 2, Endian.little),
        ),
      );
      if (name == 'WordDocument' &&
          view.getUint32(entry + 120, Endian.little) > 0) {
        return true;
      }
    }
    directory = fat[directory];
  }
  return false;
}
