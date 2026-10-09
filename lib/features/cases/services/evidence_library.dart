import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/evidence_model.dart';

class EvidenceLibraryResult {
  const EvidenceLibraryResult(this.photos, {this.failedCount = 0});
  final List<EvidenceModel> photos;
  final int failedCount;
}

typedef EvidenceLibraryPicker = Future<EvidenceLibraryResult> Function();

final evidenceLibraryPickerProvider = Provider<EvidenceLibraryPicker>(
  (ref) => DeviceEvidenceLibrary().pickPhotos,
);

class DeviceEvidenceLibrary {
  DeviceEvidenceLibrary({Future<List<XFile>> Function()? pickImages})
    : _pickImages =
          pickImages ??
          (() => ImagePicker().pickMultiImage(requestFullMetadata: false));
  final Future<List<XFile>> Function() _pickImages;
  bool _picking = false;

  Future<EvidenceLibraryResult> pickPhotos() async {
    if (_picking) return const EvidenceLibraryResult([]);
    _picking = true;
    try {
      final files = await _pickImages();
      final photos = <EvidenceModel>[];
      var failed = 0;
      for (final file in files) {
        try {
          photos.add(await EvidenceModel.fromFile(file));
        } catch (_) {
          // A bad or inaccessible file must not discard other selected photos.
          failed++;
        }
      }
      return EvidenceLibraryResult(photos, failedCount: failed);
    } finally {
      _picking = false;
    }
  }
}

String evidenceLibraryErrorMessage(Object error) {
  if (error is PlatformException &&
      (error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('restricted'))) {
    return 'Photo library access was denied. Check photo access in your device settings and try again.';
  }
  if (error is MissingPluginException || error is UnsupportedError) {
    return 'Photo selection is unavailable on this device.';
  }
  return 'Unable to open or read the photo library. Please try again.';
}
