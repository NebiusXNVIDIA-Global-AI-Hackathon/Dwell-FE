import 'package:material_ui/material_ui.dart';

import '../../../../core/theme.dart';
import '../../models/case_detail.dart';
import '../../models/case_stage.dart';
import '../case_detail_format.dart';
import '../case_detail_tokens.dart';
import 'case_status_badge.dart';

class CaseHeader extends StatelessWidget {
  const CaseHeader({super.key, required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CaseDetailSizes.headerInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Case  #${detail.caseNumber}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaseDetailText.caseNumber,
          ),
          const SizedBox(height: Gap.sm),
          Text(
            detail.headline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaseDetailText.caseTitle,
          ),
          const SizedBox(height: Gap.sm),
          Text(
            detail.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaseDetailText.meta,
          ),
          const SizedBox(height: Gap.card),
          Row(
            children: [
              CaseStatusBadge.stage(detail.stage.badge),
              const SizedBox(width: Gap.sm),
              CaseStatusBadge.priority(detail.priority),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  CaseDetailFormat.createdShort(detail.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: CaseDetailText.meta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
