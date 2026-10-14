import 'package:material_ui/material_ui.dart';

import '../data/home_mock_data.dart';

class CurrentCaseCard extends StatelessWidget {
  const CurrentCaseCard({super.key, required this.data, this.onViewCase});
  final HomeCaseData data;
  final VoidCallback? onViewCase;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(width: 48, height: 35, color: const Color(0xFFE8ABA7)),
            Container(width: 48, height: 28, color: const Color(0xFFF0CE9C)),
          ],
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE3E0D4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 3,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 23, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            fontSize: 24,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF243B53),
                          ),
                        ),
                        Text(
                          'Case #${data.number}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF929292),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Location: ${data.location}',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF243B53),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last update ${data.lastUpdate}',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: Color(0xFF929292),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _CaseProgress(createdDate: data.createdDate),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 43),
              child: FilledButton(
                onPressed: onViewCase,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF243B53),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('View Case'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CaseProgress extends StatelessWidget {
  const _CaseProgress({required this.createdDate});
  final String createdDate;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              createdDate,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF606060)),
            ),
          ),
          const Expanded(flex: 5, child: SizedBox()),
        ],
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 21,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              right: 0,
              child: Row(
                children: [
                  const Spacer(flex: 2),
                  Expanded(
                    flex: 4,
                    child: Container(height: 2, color: const Color(0xFF243B53)),
                  ),
                  Expanded(
                    flex: 5,
                    child: Container(height: 2, color: const Color(0xFFD6D6D6)),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    flex: i == 2 ? 3 : 2,
                    child: Center(
                      child: Container(
                        width: 21,
                        height: 21,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < 2
                              ? const Color(0xFF243B53)
                              : const Color(0xFFF8F8F8),
                          border: i == 2
                              ? Border.all(
                                  color: const Color(0xFFD6D6D6),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: i == 0
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : i == 1
                            ? const Center(
                                child: SizedBox(
                                  width: 9,
                                  height: 9,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 7),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Case\nCreated',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                color: Color(0xFF243B53),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Notified\nLandlord',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                color: Color(0xFF243B53),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Waiting for\nLandlord’s Response',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                color: Color(0xFF637381),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
