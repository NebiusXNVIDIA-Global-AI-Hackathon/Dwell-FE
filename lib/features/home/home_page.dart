import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/widgets/profile_avatar.dart';
import 'data/home_mock_data.dart';
import 'widgets/current_case_card.dart';
import 'widgets/needs_attention_card.dart';
import 'widgets/next_step_checklist.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const ValueKey('home-scroll'),
          // The shell extends Home behind its fixed navigation. Reserve room
          // only at the scroll end so the last action can clear that layer.
          padding: EdgeInsets.fromLTRB(
            10,
            22,
            10,
            MediaQuery.paddingOf(context).bottom + 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 570),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/dwell_logo.svg',
                          width: 50,
                          height: 48,
                          excludeFromSemantics: true,
                        ),
                        Expanded(
                          child: Text(
                            'Dwell',
                            style: const TextStyle(
                              fontSize: 40,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF243B53),
                            ),
                          ),
                        ),
                        const ProfileAvatar(nickname: 'SJ', size: 42),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: CurrentCaseCard(
                      data: homeCurrentCase,
                      onViewCase: () => context.goNamed('cases'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: NextStepChecklist(items: homeChecklist),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Needs Your Attention',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF243B53),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // No attention detail route exists yet.
                      const Text(
                        'View detail',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF606060),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xFF606060),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  NeedsAttentionCard(
                    message: homeAttentionMessage,
                    onCheckUnit: () => context.go('/my-place'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
