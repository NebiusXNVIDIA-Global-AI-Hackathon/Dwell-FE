import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/evidence_model.dart';
import 'evidence_document_format.dart';
import 'evidence_media_platform.dart';

class EvidenceDocumentResult {
  const EvidenceDocumentResult(this.documents, {this.failures = const []});
  final List<EvidenceModel> documents;
  final List<String> failures;
}

typedef EvidenceDocumentPicker = Future<EvidenceDocumentResult> Function(
  Set<String> existing,
);
final evidenceDocumentPickerProvider = Provider<EvidenceDocumentPicker>((ref) {
  final picker = DeviceEvidenceDocuments();
  return picker.pickDocuments;
});

class DeviceEvidenceDocuments {
  DeviceEvidenceDocuments({
    Future<List<PlatformFile>> Function()? pickFiles,
    Future<EvidenceModel> Function(Uint8List, String)? save,
    Future<void> Function(PlatformFile)? release,
  }) : _pickFiles =
           pickFiles ??
           (() => FilePicker.pickFiles(
             type: FileType.custom,
             allowedExtensions: evidenceDocumentExtensions,
           )),
       _save =
           save ??
           ((data, name) => EvidenceModel.fromDocument(data, name: name)),
       _release = release ?? ((file) => releasePickedDocument(file.uri));
  final Future<List<PlatformFile>> Function() _pickFiles;
  final Future<EvidenceModel> Function(Uint8List, String) _save;
  final Future<void> Function(PlatformFile) _release;
  bool _picking = false;

  Future<EvidenceDocumentResult> pickDocuments(
    Set<String> existing, {
    List<PlatformFile>? files,
  }) async {
    if (_picking) return const EvidenceDocumentResult([]);
    _picking = true;
    final documents = <EvidenceModel>[];
    final failures = <String>[];
    try {
      final picked =
          files ?? await _pickFiles(); // No timeout while a user is choosing.
      final fingerprints = {...existing};
      for (final file in picked) {
        final name = safeEvidenceDocumentName(file.name);
        EvidenceModel? saved;
        try {
          if (!evidenceDocumentExtensions.contains(
            name.split('.').last.toLowerCase(),
          )) {
            throw const FormatException('Choose a PDF, Word, JPG or PNG file.');
          }
          final length =
              file.lengthSync() ??
              await file.length().timeout(const Duration(seconds: 15));
          if (length != null && length > evidenceDocumentLimit) {
            throw const FormatException('The file exceeds the 10 MB limit.');
          }
          if (length == 0) throw const FormatException('The file is empty.');
          final buffer = BytesBuilder(copy: false);
          await for (final chunk in file.readAsByteStream().timeout(
            const Duration(seconds: 15),
          )) {
            if (buffer.length + chunk.length > evidenceDocumentLimit) {
              throw const FormatException('The file exceeds the 10 MB limit.');
            }
            buffer.add(chunk);
          }
          final data = buffer.takeBytes();
          if (length != null && length != data.length) {
            throw const FormatException(
              'The file could not be read completely.',
            );
          }
          // Validation, hashing and platform storage happen once per file.
          saved = await _save(data, name);
          if (!fingerprints.add(saved.documentFingerprint!)) {
            throw const FormatException('This document is already attached.');
          }
          documents.add(saved);
          saved = null;
        } catch (error) {
          if (saved != null) {
            try {
              await saved.dispose();
            } catch (_) {}
          }
          final reason = error is FormatException
              ? error.message
              : error is TimeoutException
              ? 'Reading this document timed out.'
              : 'The file could not be read or saved.';
          failures.add('$name: $reason');
        } finally {
          try {
            await _release(file).timeout(const Duration(seconds: 5));
          } catch (_) {}
        }
      }
      return EvidenceDocumentResult(
        List.unmodifiable(documents),
        failures: List.unmodifiable(failures),
      );
    } catch (_) {
      for (final document in documents) {
        await document.dispose();
      }
      rethrow;
    } finally {
      _picking = false;
    }
  }
}

String evidenceDocumentPickerError(Object error) {
  if (error is PlatformException) {
    final code = '${error.code} ${error.message}'.toLowerCase();
    if (code.contains('denied') ||
        code.contains('permission') ||
        code.contains('security')) {
      return 'Document access was denied. Please choose a file you can access.';
    }
  }
  return 'Unable to open the document picker. Please try again.';
}
