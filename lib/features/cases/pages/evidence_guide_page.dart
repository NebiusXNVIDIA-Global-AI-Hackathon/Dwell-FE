import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/creation/case_creation_bottom.dart';
import '../widgets/creation/case_creation_header.dart';

class EvidenceGuidePage extends StatelessWidget {
  const EvidenceGuidePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F7),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: CaseCreationHeader(
                title: 'Before You Go',
                currentStep: 5,
                showStepDetails: false,
                onBack: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(height: 28),
            const Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(
                          "Let's capture the right evidence",
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF243B53),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      _GuideCard(
                        title: '1. Overall View',
                        description: 'Show the entire area',
                        image: 'overall_view.png',
                      ),
                      SizedBox(height: 8),
                      _GuideCard(
                        title: '2. Close-up',
                        description: 'Get a closer look at the damage.',
                        image: 'close_up.png',
                      ),
                      SizedBox(height: 8),
                      _GuideCard(
                        title: '3. Video or Recording (if visible)',
                        description:
                            'Show where the issue is coming from lively.',
                        image: 'video_recording.png',
                        showPlay: true,
                      ),
                      SizedBox(height: 8),
                      _GuideCard(
                        title: '4. Surrounding area',
                        description: 'Include nearby',
                        image: 'surrounding_area.png',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: LayoutBuilder(
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
                  final height = (label.height + 24).clamp(
                    56.0,
                    double.infinity,
                  );
                  label.dispose();
                  return CaseCreationBottom(
                    enabled: true,
                    height: height,
                    label: 'Start Adding Evidence',
                    onNext: () => Navigator.of(context).pop(true),
                  );
                },
              ),
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
    constraints: const BoxConstraints(minHeight: 87),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F7F7),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFAAB3BC)),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 79,
            height: 66,
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF243B53),
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF627381),
                  fontSize: 16,
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
