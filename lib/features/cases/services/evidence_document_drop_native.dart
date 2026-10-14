import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

VoidCallback listenEvidenceDocumentDrop({
  required bool Function(double, double) contains,
  required void Function(List<PlatformFile>) onDrop,
  required void Function(bool) onHover,
}) => () {};
