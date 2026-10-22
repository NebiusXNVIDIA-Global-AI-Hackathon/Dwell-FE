import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../case_detail_tokens.dart';

class CurrentStatusCard extends StatelessWidget {
  const CurrentStatusCard({
    super.key,
    required this.statusText,
    required this.createdText,
    required this.onSendNotice,
    this.illustrationPath,
  });

  final String statusText;
  final String createdText;
  final VoidCallback onSendNotice;
  final String? illustrationPath;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CaseDetailColors.statusPanel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                CaseDetailSizes.statusInset,
                Gap.md,
                0,
                Gap.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Current Status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaseDetailText.sectionTitle,
                  ),
                  const SizedBox(height: Gap.sm),
                  Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaseDetailText.statusHeadline,
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    createdText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CaseDetailText.statusMeta,
                  ),
                  const SizedBox(height: Gap.sm),
                  _SendNoticeButton(onTap: onSendNotice),
                ],
              ),
            ),
          ),
          const SizedBox(width: Gap.xs),
          // Illustration slot stays empty until the asset is added
          SizedBox(
            width: CaseDetailSizes.illustrationWidth,
            child: illustrationPath == null
                ? null
                : Image.asset(
                    illustrationPath!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topLeft,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SendNoticeButton extends StatelessWidget {
  const _SendNoticeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CaseDetailColors.notice,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          height: CaseDetailSizes.noticeButtonHeight,
          child: Center(
            child: Text(
              'Send a notice',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaseDetailText.noticeButton,
            ),
          ),
        ),
      ),
    );
  }
}
