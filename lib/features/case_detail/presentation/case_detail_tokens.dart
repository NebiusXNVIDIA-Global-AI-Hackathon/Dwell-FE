import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';

abstract final class CaseDetailColors {
  static const navy = AppColors.navy;
  static const background = AppColors.bg;
  static const surface = AppColors.surface;
  static const body = AppColors.textBody;
  static const muted = AppColors.textMuted;
  static const meta = AppColors.iconGray;
  static const subtle = AppColors.textSubtle;
  static const divider = AppColors.divider;
  static const accent = AppColors.risingAction;
  static const notice = AppColors.unreadDot;
  static const statusPanel = AppColors.insightCard;
  static const swipeDelete = AppColors.danger;
  static const warningText = AppColors.warningText;

  static const destructive = Color(0xFFFF0000);
  static const highSoft = Color(0xFFE8ACA7);
  static const highText = Color(0xFFC60202);
  static const track = Color(0xFFD6D6D6);
  static const upcomingLabel = Color(0xFF647484);
  static const eventLine = Color(0xFFC2D4D7);
  static const folder = Color(0xFFB6AC98);
  static const folderGlass = Color(0x33292318);
  static const folderEdge = Color(0x80FFFFFF);
  static const glassPill = Color(0x33FFFFFF);
  static const toast = Color(0xFF4F4D4E);
  static const dim = Color(0x33000000);
  static const cardShadow = Color(0x1A000000);
  static const floatShadow = Color(0x40000000);
}

// Figma 390 × 844 values rounded to the nearest multiple of 4.
abstract final class CaseDetailSizes {
  static const pageInset = Gap.screenH;
  static const headerInset = 32.0;
  static const statusInset = 28.0;
  static const appBarStart = Gap.md;
  static const appBarEnd = Gap.card;
  static const appBarTop = Gap.md;
  static const backButton = 32.0;
  static const backRadius = Gap.sm;
  static const backIcon = 16.0;
  static const menuButton = 32.0;
  static const menuIcon = 24.0;

  static const badgeHeight = 24.0;
  static const badgePadding = Gap.card;

  static const illustrationWidth = 132.0;
  static const noticeButtonHeight = 32.0;

  static const timelineNode = 20.0;
  static const timelineInnerDot = 8.0;
  static const timelineCheck = 16.0;
  static const timelineLine = 2.0;
  static const timelineBorder = 2.0;
  static const timelineStart = Gap.sm;
  static const timelineSpacing = 104.0;
  static const timelineLabelWidth = 120.0;
  static const timelineFadeStop = 0.4;
  static const linkIcon = 16.0;

  static const checklistHeight = 44.0;
  static const checklistRadius = 4.0;
  static const checklistAccent = 12.0;
  static const checklistTextStart = 16.0;
  static const checklistTrailingEnd = Gap.screenH;
  static const checklistToggle = 16.0;
  static const checklistToggleBorder = 1.5;
  static const checklistIcon = 16.0;
  static const swipeExtent = 52.0;

  static const folderSize = 136.0;
  static const folderTabWidth = 48.0;
  static const folderTabHeight = 24.0;
  static const folderRadius = Gap.sm;
  static const folderBottomRadius = Gap.card;
  static const folderThumbTop = 36.0;
  static const folderThumbHeight = 88.0;
  static const folderGlassTop = 60.0;
  static const pillWidth = 72.0;

  static const ctaHeight = 56.0;
  static const ctaRadius = Gap.sm;

  static const menuWidth = 156.0;
  static const menuItemHeight = 48.0;
  static const menuItemIcon = 16.0;
  static const menuRadius = Gap.sm;

  static const dialogWidth = 320.0;
  static const dialogInset = 32.0;
  static const dialogRadius = Gap.card;
  static const dialogActionHeight = 44.0;

  static const toastHeight = 48.0;
  static const toastIcon = 24.0;
  static const toastTop = 32.0;

  static const eventDot = 12.0;
  static const eventInnerDot = 4.0;
  static const eventDotTop = Gap.xs;
  static const eventGap = 36.0;

  static const shadowOffset = Offset(0, 4);
  static const shadowBlur = 4.0;
}

abstract final class CaseDetailGaps {
  static const appBarToHeader = Gap.lg;
  static const headerToStatus = Gap.lg;
  static const statusToTimeline = Gap.screenH;
  static const titleToTimeline = Gap.screenH;
  static const timelineToChecklist = 32.0;
  static const titleToList = Gap.card;
  static const checklistToEvidence = 52.0;
  static const evidenceToCta = Gap.lg;
  static const ctaBottom = 28.0;
  static const headerToEvents = 64.0;
}

abstract final class CaseDetailText {
  static const appBarTitle = TextStyle(
    color: CaseDetailColors.navy,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.72,
  );
  static const caseNumber = TextStyle(
    color: CaseDetailColors.navy,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.72,
  );
  static const caseTitle = TextStyle(
    color: CaseDetailColors.navy,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const meta = TextStyle(
    color: CaseDetailColors.meta,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const badge = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  static const sectionTitle = TextStyle(
    color: CaseDetailColors.navy,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const statusHeadline = TextStyle(
    color: CaseDetailColors.notice,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const statusMeta = TextStyle(
    color: CaseDetailColors.subtle,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const noticeButton = TextStyle(
    color: CaseDetailColors.surface,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const link = TextStyle(
    color: CaseDetailColors.body,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.36,
  );
  static const timelineDate = TextStyle(
    color: CaseDetailColors.body,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  static const timelineLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const checklist = TextStyle(
    color: CaseDetailColors.body,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  static const folderLabel = TextStyle(
    color: CaseDetailColors.surface,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const cta = TextStyle(
    color: CaseDetailColors.surface,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.48,
  );
  static const menuItem = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
  static const dialogTitle = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const dialogBody = TextStyle(
    color: CaseDetailColors.body,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const dialogAction = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.45,
  );
  static const toast = TextStyle(
    color: CaseDetailColors.surface,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const eventDate = TextStyle(
    color: CaseDetailColors.meta,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const eventTitle = TextStyle(
    color: Colors.black,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const eventBody = TextStyle(
    color: CaseDetailColors.body,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
