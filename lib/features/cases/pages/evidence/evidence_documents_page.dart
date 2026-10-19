import 'package:lucide_icons_flutter/lucide_icons_300.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/evidence_model.dart';
import '../../services/evidence_documents.dart';
import '../../services/evidence_document_drop.dart';
import '../../services/evidence_media_platform.dart';
import '../../widgets/creation/evidence/evidence_document_preview.dart';

class EvidenceDocumentsPage extends ConsumerStatefulWidget {
  const EvidenceDocumentsPage({super.key, this.existing = const {}});
  final Set<String> existing;
  @override
  ConsumerState<EvidenceDocumentsPage> createState() =>
      _EvidenceDocumentsPageState();
}

class _EvidenceDocumentsPageState extends ConsumerState<EvidenceDocumentsPage> {
  final _files = <EvidenceModel>[];
  final _zone = GlobalKey();
  VoidCallback? _stopDrop;
  bool _busy = false, _closing = false, _canPop = false, _hover = false;
  @override
  void initState() {
    super.initState();
    _stopDrop = listenEvidenceDocumentDrop(
      contains: (x, y) {
        if (!mounted || _closing) return false;
        final box = _zone.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.hasSize) return false;
        return (box.localToGlobal(Offset.zero) & box.size).contains(
          Offset(x, y),
        );
      },
      onDrop: (files) => unawaited(_pick(files: files)),
      onHover: (hover) {
        if (mounted && !_closing && _hover != hover) {
          setState(() => _hover = hover);
        }
      },
    );
  }

  Set<String> get _fingerprints => {
    ...widget.existing,
    ..._files.map((f) => f.documentFingerprint!).toSet(),
  };

  Future<void> _pick({List<PlatformFile>? files}) async {
    if (_busy || _closing) {
      if (files != null) {
        for (final file in files) {
          await releasePickedDocument(file.uri);
        }
      }
      return;
    }
    setState(() => _busy = true);
    try {
      final result = files == null
          ? await ref.read(evidenceDocumentPickerProvider)(_fingerprints)
          : await DeviceEvidenceDocuments().pickDocuments(
              _fingerprints,
              files: files,
            );
      if (!mounted || _closing) {
        for (final file in result.documents) {
          await file.dispose();
        }
        return;
      }
      setState(() => _files.addAll(result.documents));
      if (result.failures.isNotEmpty) {
        _message(
          result.failures.take(3).join('\n') +
              (result.failures.length > 3
                  ? '\n${result.failures.length - 3} more files could not be added.'
                  : ''),
        );
      }
    } catch (error) {
      if (mounted && !_closing) _message(evidenceDocumentPickerError(error));
    } finally {
      if (mounted && !_closing) setState(() => _busy = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
    ),
  );
  Future<void> _remove(EvidenceModel file) async {
    if (_busy || _closing) return;
    setState(() => _files.remove(file));
    try {
      await file.dispose();
    } catch (_) {}
  }

  Future<void> _finish({bool upload = false}) async {
    if (_closing || (upload && (_busy || _files.isEmpty))) return;
    _closing = true;
    final result = List<EvidenceModel>.of(_files);
    _files.clear();
    if (!upload) {
      for (final file in result) {
        unawaited(file.dispose().catchError((Object _) {}));
      }
    }
    setState(() => _canPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      Navigator.of(context).pop(upload ? result : null);
    } else if (upload) {
      for (final file in result) {
        unawaited(file.dispose().catchError((Object _) {}));
      }
    }
  }

  @override
  void dispose() {
    _closing = true;
    _stopDrop?.call();
    for (final file in _files) {
      unawaited(file.dispose().catchError((Object _) {}));
    }
    _files.clear();
    super.dispose();
  }

  Widget _fileRow(EvidenceModel file) => Container(
    key: ValueKey('document-row-${file.id}'),
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E5E5)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            color: const Color(0xFFE3E8EF),
            child: SizedBox(
              width: 62,
              height: 62,
              child: EvidenceDocumentIcon(evidence: file),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF243B53),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${evidenceDocumentLabel(file)} · ${evidenceDocumentSize(file)}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF627381)),
              ),
            ],
          ),
        ),
        IconButton(
          key: ValueKey('remove-document-${file.id}'),
          tooltip: 'Remove ${file.fileName}',
          onPressed: _busy ? null : () => _remove(file),
          icon: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: const Icon(
              LucideIcons.x,
              size: 18,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope<List<EvidenceModel>>(
    canPop: _canPop,
    onPopInvokedWithResult: (popped, _) {
      if (!popped) _finish();
    },
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 12, bottom: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: _finish,
                    icon: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        size: 20,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Upload Document',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 34),
                      CustomPaint(
                        key: _zone,
                        foregroundPainter: _DocumentDashBorder(),
                        child: Material(
                          color: _hover
                              ? const Color(0xFFD6E3F2)
                              : const Color(0xFFE3E8EF),
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: const ValueKey('document-choose-files'),
                            onTap: _busy ? null : _pick,
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 260),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                52,
                                16,
                                36,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons300.fileText,
                                    size: 60,
                                    color: Color(0xFF243B53),
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    kIsWeb
                                        ? 'Choose files or drag and drop'
                                        : 'Choose files',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF243B53),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'PDF, JPG, PNG, or DOCS\n(Max 10MB per file)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.2,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF627381),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      const SizedBox(height: 52),
                      Text(
                        _files.isEmpty
                            ? 'Selected File'
                            : 'Selected File (${_files.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF243B53),
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final file in _files) _fileRow(file),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  key: const ValueKey('document-upload'),
                  onPressed: _files.isEmpty || _busy
                      ? null
                      : () => _finish(upload: true),
                  style: ElevatedButton.styleFrom(
                    side: BorderSide.none,
                    elevation: 0,
                    backgroundColor: const Color(0xFF243B53),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E5E5),
                    disabledForegroundColor: const Color(0xFFA6A6A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Upload',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DocumentDashBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    final paint = Paint()
      ..color = const Color(0xFF8D9FB8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var offset = 0.0; offset < metric.length; offset += 16) {
        canvas.drawPath(
          metric.extractPath(offset, math.min(offset + 8, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DocumentDashBorder oldDelegate) => false;
}
