import 'package:intl/intl.dart';

import '../../cases/models/case_model.dart';
import '../models/case_stage.dart';

abstract final class CaseDetailFormat {
  static String ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }

  // e.g. Created Sep 28th, 2026
  static String createdShort(DateTime date) =>
      'Created ${DateFormat('MMM').format(date)} ${ordinal(date.day)}, ${date.year}';

  // e.g. Case created September 28th, 10:00 AM
  static String createdLong(DateTime date) =>
      'Case created ${DateFormat('MMMM').format(date)} ${ordinal(date.day)}, ${DateFormat('h:mm a').format(date)}';

  // e.g. Sep 28th, 2026  8:12PM
  static String eventTime(DateTime date) =>
      '${DateFormat('MMM').format(date)} ${ordinal(date.day)}, ${date.year}  ${DateFormat('h:mma').format(date)}';

  static String stepDate(DateTime date) => DateFormat('M/d').format(date);

  static String folderDate(DateTime date) =>
      DateFormat('MM/dd/yyyy').format(date);

  static String itemCount(int count) =>
      '$count ${count == 1 ? 'item' : 'items'}';

  static String status(CaseStatus status) => switch (status) {
    CaseStatus.active => 'Active',
    CaseStatus.logged => 'Logged',
    CaseStatus.resolved => 'Resolved',
  };

  static String priority(CaseSeverity severity) => switch (severity) {
    CaseSeverity.low => 'Low',
    CaseSeverity.medium => 'Medium',
    CaseSeverity.high => 'High',
  };

  static String stageBadge(CaseStageBadge badge) => switch (badge) {
    CaseStageBadge.logged => 'Logged',
    CaseStageBadge.inProgress => 'In Progress',
    CaseStageBadge.resolved => 'Resolved',
  };

  static String stage(CaseStage stage) => switch (stage) {
    CaseStage.created => 'Case created',
    CaseStage.waitingResponse => 'Waiting for response',
    CaseStage.responseOverdue => 'Response overdue',
    CaseStage.scheduling => 'Scheduling the repair',
    CaseStage.followUpWaiting => 'Follow-up sent',
    CaseStage.followUpOverdue => 'Follow-up overdue',
    CaseStage.repairScheduled => 'Repair scheduled',
    CaseStage.repairDay => 'Repair day',
    CaseStage.repairInProgress => 'Repair in progress',
    CaseStage.landlordRefused => 'Landlord refused',
    CaseStage.blameShifting => 'Landlord blames you',
    CaseStage.reported311 => 'Reported to 311',
    CaseStage.hpdInspection => 'HPD inspection',
    CaseStage.violationIssued => 'Violation issued',
    CaseStage.resolved => 'Resolved',
    CaseStage.recurred => 'Recurred',
    CaseStage.selfRepair => 'Repairing it yourself',
    CaseStage.repairCostClaim => 'Repair cost claim',
    CaseStage.insuranceClaim => 'Insurance claim',
  };
}
