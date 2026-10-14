import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import '../services/evidence_document_format.dart';

import '../services/evidence_media_platform.dart';
import '../services/evidence_media_format.dart';

enum EvidenceType { photo, video, audio, document }

enum EvidenceCleanupStatus {
  active,
  waitingForReaders,
  deleting,
  pending,
  completed,
  failed,
}

const evidenceReaderReleaseTimeout = Duration(seconds: 15);

/// Session evidence: photos preview independent bytes and optionally own their
/// source via an explicit cleanup callback; recordings own a private cache file.
class EvidenceModel {
  EvidenceModel._({
    required this.id,
    required this.file,
    required this._bytes,
    required this.mimeType,
    required this.addedAt,
    this.type = EvidenceType.photo,
    this.duration,
    this._videoDirectory,
    this.documentSize,
    this.documentFingerprint,
    this._documentName,
    this._documentCleanup,
    this._documentPreviewBytes,
    this._photoCleanup,
    this.photoWidth,
    this.photoHeight,
  });
  static int _sequence = 0;
  final String id;
  final XFile file;
  Uint8List _bytes;
  Uint8List get bytes => _bytes;
  final int? photoWidth;
  final int? photoHeight;
  final _photoProviders = <ImageProvider<Object>>{};

  /// Decode enough pixels for cover while preserving the source aspect ratio.
  ImageProvider<Object> photoPreview(double width, double height, double dpr) {
    if (isDisposed) throw StateError('Evidence has been removed.');
    final scale = math.min(
      1.0,
      math.max(width * dpr / photoWidth!, height * dpr / photoHeight!),
    );
    final targetWidth = (photoWidth! * scale).ceil().clamp(1, photoWidth!);
    final provider = ResizeImage.resizeIfNeeded(
      targetWidth,
      null,
      MemoryImage(bytes),
    );
    _photoProviders.add(provider);
    return provider;
  }

  final String mimeType;
  final DateTime addedAt;
  final EvidenceType type;
  final Duration? duration;
  final int? documentSize;
  final String? documentFingerprint;
  final String? _documentName;
  Future<void> Function()? _documentCleanup;
  Uint8List? _documentPreviewBytes;
  Uint8List? get documentPreviewBytes => _documentPreviewBytes;
  List<double> _audioLevels = const [];
  List<double> get audioLevels => _audioLevels;
  List<Duration> _audioLevelTimes = const [];
  List<Duration> get audioLevelTimes => _audioLevelTimes;
  Duration? audioCaptureDuration;
  void setAudioLevels(
    List<double> levels, {
    List<Duration> times = const [],
    Duration? captureDuration,
  }) {
    if (type == EvidenceType.audio && !isDisposed) {
      _audioLevels = List.unmodifiable(levels);
      _audioLevelTimes = List.unmodifiable(times);
      audioCaptureDuration = captureDuration;
    }
  }

  final Directory? _videoDirectory;
  Future<void> Function()? _photoCleanup;
  Future<void>? _disposing;
  Future<void>? _cleanupCompletion;
  EvidenceCleanupStatus _cleanupStatus = EvidenceCleanupStatus.active;
  EvidenceCleanupStatus get cleanupStatus => _cleanupStatus;
  Future<void>? get cleanupCompletion => _cleanupCompletion;
  @visibleForTesting
  int get activeMediaReaders => _videoReaders;
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

  String get fileName => _documentName ?? file.name;

  static Future<EvidenceModel> fromDocument(
    Uint8List data, {
    required String name,
    Directory? storageDirectory,
  }) async {
    final safeName = safeEvidenceDocumentName(name);
    final mime = validateEvidenceDocument(data, safeName);
    Uint8List? preview;
    if (mime.startsWith('image/')) {
      final codec = await ui.instantiateImageCodec(
        data,
        targetWidth: 256,
        allowUpscaling: false,
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          preview = (await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          ))?.buffer.asUint8List();
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    }
    final fingerprint = sha256.convert(data).toString();
    final stored = await storeEvidenceDocument(
      data,
      mime,
      safeName,
      storageDirectory: storageDirectory,
    );
    final now = DateTime.now();
    return EvidenceModel._(
      id: '${now.microsecondsSinceEpoch}-${++_sequence}',
      file: stored.file,
      bytes: Uint8List(0),
      mimeType: mime,
      addedAt: now,
      type: EvidenceType.document,
      documentSize: data.length,
      documentFingerprint: fingerprint,
      documentName: safeName,
      documentCleanup: stored.dispose,
      documentPreviewBytes: preview,
    );
  }

  static Future<EvidenceModel> fromVideo(
    XFile file, {
    required Duration duration,
    Directory? storageDirectory,
  }) async {
    if (duration < const Duration(seconds: 5)) {
      throw const FormatException('Record at least 5 seconds of video.');
    }
    if (kIsWeb) return _fromBrowserMedia(file, duration, EvidenceType.video);
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

  /// Release only explicitly owned sources and private session directories.
  Future<void> dispose() {
    if (_disposing != null) return _disposing!;
    if (type == EvidenceType.photo) {
      unawaited(MemoryImage(this.bytes).evict());
      for (final provider in _photoProviders) {
        unawaited(provider.evict());
      }
      _photoProviders.clear();
      // Mounted streams keep their own bytes until unmounted. A removed model
      // should no longer retain the encoded original.
      _bytes = Uint8List(0);
    }
    _audioLevels = const [];
    _audioLevelTimes = const [];
    audioCaptureDuration = null;
    final documentPreview = _documentPreviewBytes;
    _documentPreviewBytes = null;
    if (documentPreview != null) {
      unawaited(MemoryImage(documentPreview).evict());
    }
    final bytes = _thumbnailBytes;
    _thumbnailBytes = null;
    _thumbnail = null;
    final clear = _clearNativeThumbnailCache;
    _clearNativeThumbnailCache = null;
    if (clear != null) unawaited(clear().catchError((Object _) {}));
    if (bytes != null) unawaited(MemoryImage(bytes).evict());
    _cleanupCompletion = _deleteVideo().then(
      (_) {
        _cleanupStatus = EvidenceCleanupStatus.completed;
      },
      onError: (Object error, StackTrace stack) {
        _cleanupStatus = EvidenceCleanupStatus.failed;
        Error.throwWithStackTrace(error, stack);
      },
    );
    unawaited(_cleanupCompletion!.catchError((Object _) {}));
    return _disposing = _awaitCleanup();
  }

  Future<void> _awaitCleanup() async {
    final readers = _readersReleased;
    if (readers != null) {
      // Bound the caller's wait only. _deleteVideo keeps following the original
      // reader barrier; timeout never deletes a source still used natively.
      await readers.future.timeout(evidenceReaderReleaseTimeout);
    }
    if (type == EvidenceType.photo) {
      // Limit UI waiting, not the original cleanup operation or its ownership.
      await _cleanupCompletion!.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _cleanupStatus = EvidenceCleanupStatus.pending;
          debugPrint('[EvidencePhoto] resource cleanup still pending');
          throw TimeoutException('Photo cleanup is still pending.');
        },
      );
    } else {
      await _cleanupCompletion;
    }
  }

  Future<void> _deleteVideo() async {
    if (_videoReaders > 0) {
      _cleanupStatus = EvidenceCleanupStatus.waitingForReaders;
      _readersReleased = Completer<void>();
      await _readersReleased!.future;
    }
    _cleanupStatus = EvidenceCleanupStatus.deleting;
    final photoCleanup = _photoCleanup;
    _photoCleanup = null;
    if (photoCleanup != null) await photoCleanup();
    final directory = _videoDirectory;
    final cleanup = _documentCleanup;
    _documentCleanup = null;
    if (cleanup != null) await cleanup();
    if (kIsWeb && (type == EvidenceType.video || type == EvidenceType.audio)) {
      releaseEvidenceBlob(file);
    }
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
    if (kIsWeb) return _fromBrowserMedia(file, duration, EvidenceType.audio);
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

  /// Capture output is app-owned; native deletion is restricted to app cache.
  static Future<EvidenceModel> fromCapture(
    XFile file, {
    Future<void> Function()? cleanup,
  }) => fromFile(file, cleanup: cleanup ?? () => releaseOwnedPhoto(file));

  static Future<void> _releasePhoto(Future<void> Function() cleanup) async {
    try {
      await cleanup().timeout(const Duration(seconds: 5));
    } catch (_) {
      // A failed cleanup must not mask validation errors or block other items.
      debugPrint('[EvidencePhoto] resource cleanup failed or timed out');
    }
  }

  static Future<EvidenceModel> _fromBrowserMedia(
    XFile file,
    Duration duration,
    EvidenceType type,
  ) async {
    final data = await file.readAsBytes();
    final format = evidenceMediaFormat(data, audio: type == EvidenceType.audio);
    final owned = createEvidenceBlob(
      data,
      format.mime,
      'recording.${format.extension}',
    );
    final now = DateTime.now();
    return EvidenceModel._(
      id: '${now.microsecondsSinceEpoch}-${++_sequence}',
      file: owned,
      bytes: Uint8List(0),
      mimeType: format.mime,
      addedAt: now,
      type: type,
      duration: duration,
    );
  }

  /// Borrowed by default. An explicit callback transfers only app-owned output;
  /// validation failure releases it here, success transfers it to the model.
  static Future<EvidenceModel> fromFile(
    XFile file, {
    Future<void> Function()? cleanup,
  }) async {
    try {
      return await _fromPhoto(file, cleanup);
    } catch (_) {
      if (cleanup != null) await _releasePhoto(cleanup);
      rethrow;
    }
  }

  static Future<EvidenceModel> _fromPhoto(
    XFile file,
    Future<void> Function()? cleanup,
  ) async {
    // Complete all file reads before publishing the model. Every photo preview
    // decodes these bytes, so deleting its source cannot race an image decoder.
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
    // Inspect dimensions without decoding the original frame; still decode a
    // small frame to reject corrupt data rather than trusting only its header.
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    late int width, height;
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        width = descriptor.width;
        height = descriptor.height;
        final scale = math.min(1.0, 64 / math.max(width, height));
        final codec = await descriptor.instantiateCodec(
          targetWidth: math.max(1, (width * scale).ceil()),
          targetHeight: math.max(1, (height * scale).ceil()),
        );
        try {
          final frame = await codec.getNextFrame();
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
    final now = DateTime.now();
    return EvidenceModel._(
      id: '${now.microsecondsSinceEpoch}-${++_sequence}',
      file: file,
      bytes: bytes,
      mimeType: mime,
      addedAt: now,
      photoCleanup: cleanup,
      photoWidth: width,
      photoHeight: height,
    );
  }
}
