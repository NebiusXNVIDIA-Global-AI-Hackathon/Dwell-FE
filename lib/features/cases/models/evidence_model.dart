import 'dart:async';
import 'dart:io';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

enum EvidenceType { photo, video }

/// Session evidence: photos share bytes; videos own a private cache file.
class EvidenceModel {
  EvidenceModel._({
    required this.id,
    required this.file,
    required this.bytes,
    required this.mimeType,
    required this.addedAt,
    this.type = EvidenceType.photo,
    this.duration,
    this._videoDirectory,
  });
  static int _sequence = 0;
  final String id;
  final XFile file;
  final Uint8List bytes;
  final String mimeType;
  final DateTime addedAt;
  final EvidenceType type;
  final Duration? duration;
  final Directory? _videoDirectory;
  Future<void>? _disposing;
  int _videoReaders = 0;
  Completer<void>? _readersReleased;

  void retainVideo() {
    if (_disposing != null) throw StateError('Evidence has been removed.');
    _videoReaders++;
  }

  void releaseVideo() {
    if (_videoReaders > 0 && --_videoReaders == 0) {
      _readersReleased?.complete();
      _readersReleased = null;
    }
  }

  String get fileName => file.name;

  static Future<EvidenceModel> fromVideo(
    XFile file, {
    required Duration duration,
    Directory? storageDirectory,
  }) async {
    if (duration < const Duration(seconds: 5)) {
      throw const FormatException('Record at least 5 seconds of video.');
    }
    final header = await file
        .openRead(0, 12)
        .fold<List<int>>([], (a, b) => a..addAll(b));
    if (header.length < 12 ||
        String.fromCharCodes(header.sublist(4, 8)) != 'ftyp') {
      throw const FormatException('The recording is not a supported video.');
    }
    final base = storageDirectory ?? await getTemporaryDirectory();
    final directory = await Directory(base.path).createTemp('dwell-video-');
    try {
      final suffix = String.fromCharCodes(header.sublist(8, 12)) == 'qt  '
          ? 'mov'
          : 'mp4';
      final destination = File('${directory.path}/recording.$suffix');
      await file.saveTo(destination.path);
      final originalSize = await file.length();
      if (originalSize == 0 || await destination.length() != originalSize) {
        throw const FormatException(
          'The recording could not be copied completely.',
        );
      }
      final now = DateTime.now();
      return EvidenceModel._(
        id: '${now.microsecondsSinceEpoch}-${++_sequence}',
        file: XFile(destination.path),
        bytes: Uint8List(0),
        mimeType: suffix == 'mov' ? 'video/quicktime' : 'video/mp4',
        addedAt: now,
        type: EvidenceType.video,
        duration: duration,
        videoDirectory: directory,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  /// Only this model's private, app-created recording directory is removed.
  Future<void> dispose() => _disposing ??= _deleteVideo();
  Future<void> _deleteVideo() async {
    if (_videoReaders > 0) {
      _readersReleased = Completer<void>();
      await _readersReleased!.future;
    }
    final directory = _videoDirectory;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

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
