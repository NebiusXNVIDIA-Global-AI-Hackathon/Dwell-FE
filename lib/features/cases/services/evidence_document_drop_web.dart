import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

base class _DroppedDocument extends PlatformFile {
  _DroppedDocument(web.File file)
    : name = file.name,
      _length = file.size,
      uri = Uri.parse(web.URL.createObjectURL(file));
  @override
  final String name;
  @override
  final Uri uri;
  final int _length;
  @override
  XFile get xFile => XFile(uri.toString(), name: name, length: _length);
  @override
  int lengthSync() => _length;
  @override
  Future<int> length() async => _length;
  @override
  Future<Uint8List> readAsBytes() => xFile.readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() => xFile.openRead();
}

VoidCallback listenEvidenceDocumentDrop({
  required bool Function(double, double) contains,
  required void Function(List<PlatformFile>) onDrop,
  required void Function(bool) onHover,
}) {
  void over(web.Event event) {
    final drag = event as web.DragEvent;
    if (!contains(drag.clientX.toDouble(), drag.clientY.toDouble())) {
      onHover(false);
      return;
    }
    drag.preventDefault();
    drag.dataTransfer?.dropEffect = 'copy';
    onHover(true);
  }

  void leave(web.Event _) => onHover(false);
  void drop(web.Event event) {
    final drag = event as web.DragEvent;
    onHover(false);
    if (!contains(drag.clientX.toDouble(), drag.clientY.toDouble())) return;
    drag.preventDefault();
    final files = drag.dataTransfer?.files;
    if (files == null) return;
    onDrop(
      List.generate(files.length, (i) => _DroppedDocument(files.item(i)!)),
    );
  }

  final overJs = over.toJS, leaveJs = leave.toJS, dropJs = drop.toJS;
  web.document.addEventListener('dragover', overJs);
  web.document.addEventListener('dragleave', leaveJs);
  web.document.addEventListener('drop', dropJs);
  return () {
    web.document.removeEventListener('dragover', overJs);
    web.document.removeEventListener('dragleave', leaveJs);
    web.document.removeEventListener('drop', dropJs);
  };
}
