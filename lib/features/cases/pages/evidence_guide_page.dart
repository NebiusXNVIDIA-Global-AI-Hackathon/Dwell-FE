import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/creation/case_creation_bottom.dart';

class EvidenceGuidePage extends StatelessWidget {
  const EvidenceGuidePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F7),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: Color(0xFF606060),
                    ),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE3E3E3)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Before You Go',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF243B53),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let's capture the right evidence",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF243B53),
                      ),
                    ),
                    SizedBox(height: 24),
                    _GuideCard(
                      title: '1. Overall View',
                      description: 'Show the entire area',
                      image: 'overall_view.png',
                    ),
                    SizedBox(height: 12),
                    _GuideCard(
                      title: '2. Close-up',
                      description: 'Get a closer look at the damage.',
                      image: 'close_up.png',
                    ),
                    SizedBox(height: 12),
                    _GuideCard(
                      title: '3. Video or Recording (if visible)',
                      description:
                          'Show where the issue is coming from lively.',
                      image: 'video_recording.png',
                      showPlay: true,
                    ),
                    SizedBox(height: 12),
                    _GuideCard(
                      title: '4. Surrounding area',
                      description: 'Include nearby',
                      image: 'surrounding_area.png',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final label = TextPainter(
                  text: TextSpan(
                    text: 'Start Adding Evidence',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout(maxWidth: constraints.maxWidth - 32);
                final height = (label.height + 24).clamp(56.0, double.infinity);
                label.dispose();
                return CaseCreationBottom(
                  enabled: true,
                  height: height,
                  label: 'Start Adding Evidence',
                  onNext: () => Navigator.of(context).pop(true),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    required this.description,
    required this.image,
    this.showPlay = false,
  });
  final String title;
  final String description;
  final String image;
  final bool showPlay;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE3E3E3)),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/evidence_guide/$image',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                // The original SVG includes its translucent circular background.
                if (showPlay)
                  Center(
                    child: SvgPicture.asset(
                      'assets/icons/case/play.svg',
                      width: 28,
                      height: 28,
                      excludeFromSemantics: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF243B53),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF627381),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
