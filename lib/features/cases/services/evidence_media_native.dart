import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

import 'evidence_player_operations.dart';

class _EvidenceNativePlayer extends VideoPlayerController
    with EvidencePlayerOperations {
  _EvidenceNativePlayer(super.file)
    : super.file(
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
      );
}

// The preview owns app lifecycle; the plugin observer cannot clean itself up
// when its creation completer is orphaned by a rejected native allocation.
VideoPlayerController evidenceMediaPlayer(XFile file) =>
    _EvidenceNativePlayer(File(file.path));
void releaseEvidenceBlob(XFile file) {}

/// Only call for files returned by our camera/image-picker adapters. Borrowed
/// gallery files never enter this path. Resolve links before checking the cache
/// boundary so a plugin path cannot cause deletion of a user original.
Future<void> releaseOwnedPhoto(XFile file, {Object? cacheDirectory}) async {
  final local = File(file.path);
  if (!await local.exists()) return;
  final cache = cacheDirectory as Directory? ?? await getTemporaryDirectory();
  final root = await cache.resolveSymbolicLinks();
  final resolved = await local.resolveSymbolicLinks();
  final boundary = '$root${Platform.pathSeparator}';
  final inside = Platform.isWindows
      ? resolved.toLowerCase().startsWith(boundary.toLowerCase())
      : resolved.startsWith(boundary);
  if (inside) {
    final owned = File(resolved);
    await owned.delete();
    // Android image_picker makes one UUID directory for each selected copy.
    // Remove only that empty directory, never recursively or the cache root.
    final parent = owned.parent;
    final name = parent.uri.pathSegments.where((part) => part.isNotEmpty).last;
    final isCacheRoot = Platform.isWindows
        ? parent.path.toLowerCase() == root.toLowerCase()
        : parent.path == root;
    if (!isCacheRoot &&
        RegExp(r'^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')
            .hasMatch(name) &&
        await parent.list().isEmpty) {
      await parent.delete();
    }
  }
}

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
