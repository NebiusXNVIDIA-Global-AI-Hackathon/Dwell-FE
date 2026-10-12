import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

VideoPlayerController evidenceMediaPlayer(XFile file) =>
    VideoPlayerController.file(File(file.path));
void releaseEvidenceBlob(XFile file) {}
Future<XFile> prepareEvidenceMedia(XFile file, {required bool audio}) async =>
    file;
XFile createEvidenceBlob(Uint8List bytes, String mime, String name) =>
    throw UnsupportedError('Blob storage is only available in a browser.');

Future<({XFile file, Future<void> Function() dispose})> storeEvidenceDocument(
  Uint8List bytes,
  String mime,
  String name, {
  Object? storageDirectory,
}) async {
  final base = storageDirectory as Directory? ?? await getTemporaryDirectory();
  final directory = await base.createTemp('dwell-document-');
  try {
    final target = File(
      '${directory.path}/document.${name.split('.').last.toLowerCase()}',
    );
    await target.writeAsBytes(bytes, flush: true);
    return (
      file: XFile(target.path, mimeType: mime),
      dispose: () async {
        if (await directory.exists()) await directory.delete(recursive: true);
      },
    );
  } catch (_) {
    await directory.delete(recursive: true);
    rethrow;
  }
}

Future<void> releasePickedDocument(Uri uri) async {
  // Delete only this picker's app-cache copy, never an original user file.
  if (uri.scheme != 'file') return;
  final cache = await getTemporaryDirectory();
  final root = await Directory('${cache.path}/file_picker').exists()
      ? await Directory('${cache.path}/file_picker').resolveSymbolicLinks()
      : null;
  if (root == null) return;
  final file = File.fromUri(uri);
  if (!await file.exists()) return;
  final resolved = await file.resolveSymbolicLinks();
  if (resolved.startsWith('$root${Platform.pathSeparator}')) {
    await file.delete();
    if (file.parent.path != root && await file.parent.list().isEmpty) {
      await file.parent.delete();
    }
  }
}
