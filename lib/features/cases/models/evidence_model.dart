import 'dart:async';
import 'dart:io';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

enum EvidenceType { photo, video, audio }

/// Session evidence: photos share bytes; recordings own a private cache file.
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
  Future<Uint8List?>? _thumbnail;
  Uint8List? _thumbnailBytes;
  Future<void> Function()? _clearNativeThumbnailCache;
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

  /// Cache successes and failures across widget rebuilds and scrolling.
  Future<Uint8List?> videoThumbnail(
    Future<Uint8List?> Function() extract, {
    Future<void> Function()? clearNativeCache,
  }) {
    if (type != EvidenceType.video || _disposing != null) return Future.value();
    _clearNativeThumbnailCache ??= clearNativeCache;
    return _thumbnail ??= _extractThumbnail(extract);
  }

  Future<Uint8List?> _extractThumbnail(Future<Uint8List?> Function() extract) {
    retainVideo();
    var expired = false;
    final clearNativeCache = _clearNativeThumbnailCache;
    final work = () async {
      try {
        final bytes = await extract();
        if (_disposing != null || expired || bytes == null || bytes.isEmpty) {
          return null;
        }
        _thumbnailBytes = bytes;
        return bytes;
      } catch (_) {
        return null;
      } finally {
        // A timeout cannot cancel a native decoder. Keep its source file alive
        // until native work actually finishes, then let normal deletion proceed.
        if ((_disposing != null || expired) && clearNativeCache != null) {
          unawaited(clearNativeCache().catchError((Object _) {}));
        }
        releaseVideo();
      }
    }();
    return work.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        expired = true;
        return null;
      },
    );
  }

  bool get isDisposed => _disposing != null;

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
  Future<void> dispose() {
    if (_disposing != null) return _disposing!;
    final bytes = _thumbnailBytes;
    _thumbnailBytes = null;
    _thumbnail = null;
    final clear = _clearNativeThumbnailCache;
    _clearNativeThumbnailCache = null;
    if (clear != null) unawaited(clear().catchError((Object _) {}));
    if (bytes != null) unawaited(MemoryImage(bytes).evict());
    return _disposing = _deleteVideo();
  }

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

  /// Audio shares the owned session-file lifetime used by recorded videos.
  static Future<EvidenceModel> fromAudio(
    XFile file, {
    required Duration duration,
    Directory? storageDirectory,
  }) async {
    if (duration <= Duration.zero) {
      throw const FormatException('Invalid audio duration.');
    }
    if (await file.length() <= 12) {
      throw const FormatException('Empty audio file.');
    }
    final header = await file
        .openRead(0, 12)
        .fold<List<int>>([], (a, b) => a..addAll(b));
    if (header.length < 12 ||
        String.fromCharCodes(header.sublist(4, 8)) != 'ftyp') {
      throw const FormatException('Unsupported audio file.');
    }
    final base = storageDirectory ?? await getTemporaryDirectory();
    final directory = await Directory(base.path).createTemp('dwell-audio-');
    try {
      final destination = File('${directory.path}/recording.m4a');
      await file.saveTo(destination.path);
      final size = await file.length();
      if (size <= 12 || await destination.length() != size) {
        throw const FormatException('Empty or incomplete audio file.');
      }
      final now = DateTime.now();
      return EvidenceModel._(
        id: '${now.microsecondsSinceEpoch}-${++_sequence}',
        file: XFile(destination.path),
        bytes: Uint8List(0),
        mimeType: 'audio/mp4',
        addedAt: now,
        type: EvidenceType.audio,
        duration: duration,
        videoDirectory: directory,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
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
