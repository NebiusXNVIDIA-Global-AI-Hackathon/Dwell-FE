import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/widgets/app_screen_header.dart';
import 'data/home_mock_data.dart';
import 'widgets/current_case_card.dart';
import 'widgets/needs_attention_card.dart';
import 'widgets/next_step_checklist.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onViewCase, this.onViewDetail});
  final ValueChanged<String>? onViewCase;
  final VoidCallback? onViewDetail;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedId = homeCases.first.number;
  final Map<String, Set<int>> _checkedByCase = {};
  final GlobalKey _attentionKey = GlobalKey();
  HomeCaseData get _selected =>
      homeCases.firstWhere((item) => item.number == _selectedId);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8F8),
    body: SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(top: AppScreenHeader.systemTopInset(context)),
        child: SingleChildScrollView(
          key: const ValueKey('home-scroll'),
          // Preserve the shell's overlapping navigation and end clearance.
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 32,
          ),
          child: Column(
            children: [
              AppScreenHeader(
                webTopPadding: 40,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/dwell_logo.svg',
                      width: 50,
                      height: 48,
                      excludeFromSemantics: true,
                    ),
                    const Text(
                      'Dwell',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF243B53),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 590),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: CurrentCaseCard(
                            data: _selected,
                            cases: homeCases,
                            onSelectCase: (id) =>
                                setState(() => _selectedId = id),
                            onViewCase: () {
                              if (widget.onViewCase case final callback?) {
                                callback(_selectedId);
                              } else {
                                // Existing destination is the list, not Case Detail.
                                context.goNamed('cases', extra: _selectedId);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: NextStepChecklist(
                            items: _selected.checklist,
                            checked: _checkedByCase[_selectedId] ?? const {},
                            onChanged: (index, checked) => setState(() {
                              final values = _checkedByCase.putIfAbsent(
                                _selectedId,
                                () => {},
                              );
                              checked
                                  ? values.add(index)
                                  : values.remove(index);
                            }),
                          ),
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
                            TextButton(
                              onPressed:
                                  widget.onViewDetail ??
                                  () {
                                    Scrollable.ensureVisible(
                                      _attentionKey.currentContext!,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      alignment: 0.5,
                                    );
                                  },
                              style:
                                  TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 24),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    splashFactory: NoSplash.splashFactory,
                                    overlayColor: Colors.transparent,
                                    foregroundColor: const Color(0xFF606060),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Pretendard Variable',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ).copyWith(
                                    backgroundColor:
                                        WidgetStateProperty.resolveWith(
                                          (states) =>
                                              states.contains(
                                                WidgetState.pressed,
                                              )
                                              ? const Color(0xFFE4E8EC)
                                              : Colors.transparent,
                                        ),
                                  ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('View detail'),
                                  Icon(Icons.chevron_right, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        NeedsAttentionCard(
                          key: _attentionKey,
                          message: homeAttentionMessage,
                          onCheckUnit: () => context.go('/my-place'),
                        ),
                      ],
                    ),
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
