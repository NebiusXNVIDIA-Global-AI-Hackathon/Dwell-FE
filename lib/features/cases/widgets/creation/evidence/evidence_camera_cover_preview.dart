import 'package:flutter/widgets.dart';

/// Crop only the preview; guides and instructions use the visible viewport.
class EvidenceCameraCoverPreview extends StatelessWidget {
  const EvidenceCameraCoverPreview({
    super.key,
    required this.aspectRatio,
    required this.preview,
    this.overlay,
  });
  final double aspectRatio;
  final Widget preview;
  final Widget? overlay;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: aspectRatio * 1000,
              height: 1000,
              child: preview,
            ),
          ),
        ),
      ),
      ?overlay,
    ],
  );
}
