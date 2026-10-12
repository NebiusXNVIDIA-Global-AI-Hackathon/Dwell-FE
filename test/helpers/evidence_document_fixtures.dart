import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

Uint8List pdfDocument({int? size}) {
  final data = Uint8List(size ?? 96);
  data.setRange(0, 9, ascii.encode('%PDF-1.7\n'));
  data.setRange(data.length - 6, data.length, ascii.encode('%%EOF\n'));
  return data;
}

Uint8List docxDocument({bool word = true}) {
  final types = utf8.encode(
    '<Types><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>',
  );
  final document = utf8.encode(
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body/></w:document>',
  );
  final archive = Archive()
    ..add(ArchiveFile('[Content_Types].xml', types.length, types))
    ..add(
      ArchiveFile(
        word ? 'word/document.xml' : 'xl/workbook.xml',
        document.length,
        document,
      ),
    );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Uint8List docDocument({String stream = 'WordDocument'}) {
  final data = Uint8List(2048);
  data.setRange(0, 8, [0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1]);
  final view = ByteData.sublistView(data);
  view.setUint16(28, 0xfffe, Endian.little);
  view.setUint16(30, 9, Endian.little);
  view.setUint32(44, 1, Endian.little);
  view.setUint32(48, 1, Endian.little);
  view.setUint32(76, 0, Endian.little);
  view.setUint32(512, 0xfffffffd, Endian.little);
  view.setUint32(516, 0xfffffffe, Endian.little);
  view.setUint32(520, 0xfffffffe, Endian.little);
  for (var i = 0; i < stream.length; i++) {
    view.setUint16(1024 + i * 2, stream.codeUnitAt(i), Endian.little);
  }
  view.setUint16(1088, (stream.length + 1) * 2, Endian.little);
  data[1090] = 2;
  view.setUint32(1140, 2, Endian.little);
  view.setUint32(1144, 512, Endian.little);
  return data;
}
