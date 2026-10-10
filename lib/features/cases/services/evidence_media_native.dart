import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';

VideoPlayerController evidenceMediaPlayer(XFile file) =>
    VideoPlayerController.file(File(file.path));
void releaseEvidenceBlob(XFile file) {}
Future<XFile> prepareEvidenceMedia(XFile file, {required bool audio}) async =>
    file;
XFile createEvidenceBlob(Uint8List bytes, String mime, String name) =>
    throw UnsupportedError('Blob storage is only available in a browser.');
