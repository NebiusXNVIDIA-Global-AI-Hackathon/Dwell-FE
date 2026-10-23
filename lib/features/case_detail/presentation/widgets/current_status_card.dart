import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/status_banner.dart';
import '../case_detail_tokens.dart';
import 'deadline_progress_bar.dart';
import 'status_action_button.dart';

/// Current Status banner; layout follows the stage banner data.
class CurrentStatusCard extends StatelessWidget {
  const CurrentStatusCard({
    super.key,
    required this.banner,
    required this.onAction,
  });

  final StatusBanner banner;
  final VoidCallback onAction;

  // Keep text clear of the illustration with a comfortable gap
  EdgeInsets get _textPadding {
    final illustration = banner.illustration;
    final atStart = banner.illustrationAtStart && banner.deadline == null;
    final clearance = illustration == null
        ? CaseDetailSizes.statusInset
        : illustration.extent + illustration.textGap;
    final bottom = banner.deadline == null ? Gap.md : 0.0;
    return atStart
        ? EdgeInsets.fromLTRB(
            clearance,
            Gap.md,
            CaseDetailSizes.bannerEndInset,
            bottom,
          )
        : EdgeInsets.fromLTRB(
            CaseDetailSizes.statusInset,
            Gap.md,
            clearance,
            bottom,
          );
  }

  // Bottom-anchored so every illustration touches the panel edge
  Widget? _illustration({double cut = CaseDetailSizes.illustrationBottomCut}) {
    final illustration = banner.illustration;
    if (illustration == null) return null;
    final atStart = banner.illustrationAtStart;
    return Positioned(
      top: illustration.fillHeight ? 0 : null,
      bottom: illustration.lift - cut,
      left: atStart ? illustration.inset : null,
      right: atStart ? null : illustration.inset,
      width: illustration.width,
      child: ExcludeSemantics(
        // Fill-height art spans the panel top to bottom and crops its side
        child: Image.asset(
          illustration.path,
          fit: illustration.fillHeight ? BoxFit.cover : BoxFit.fitWidth,
          alignment: atStart ? Alignment.bottomRight : Alignment.bottomLeft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tone = banner.tone.color;
    final text = _BannerText(banner: banner, tone: tone);
    final button = StatusActionButton(
      label: banner.action.label,
      color: tone,
      onTap: onAction,
    );
    final deadline = banner.deadline;

    return ClipRect(
      child: ColoredBox(
        color: CaseDetailColors.statusPanel,
        child: deadline == null
            ? Stack(
                children: [
                  ?_illustration(),
                  Padding(
                    padding: _textPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        text,
                        const SizedBox(height: Gap.sm),
                        button,
                      ],
                    ),
                  ),
                ],
              )
            // Waiting stages keep the illustration beside the text, above the deadline
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ?_illustration(cut: 0),
                      Padding(padding: _textPadding, child: text),
                    ],
                  ),
                  const SizedBox(height: Gap.card),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CaseDetailSizes.statusInset,
                    ),
                    child: DeadlineProgressBar(deadline: deadline),
                  ),
                  const SizedBox(height: Gap.card),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CaseDetailSizes.wideButtonInset,
                    ),
                    child: button,
                  ),
                  const SizedBox(height: Gap.md),
                ],
              ),
      ),
    );
  }
}

class _BannerText extends StatelessWidget {
  const _BannerText({required this.banner, required this.tone});

  final StatusBanner banner;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          banner.headline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaseDetailText.statusHeadline.copyWith(color: tone),
        ),
        const SizedBox(height: Gap.xs),
        for (final line in banner.details)
          Text(
            line,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: CaseDetailText.statusMeta,
          ),
      ],
    );
  }
}
