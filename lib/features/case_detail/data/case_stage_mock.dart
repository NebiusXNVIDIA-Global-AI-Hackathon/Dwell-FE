import '../models/case_stage.dart';
import '../models/case_stage_content.dart';
import '../models/status_banner.dart';
import '../models/timeline_step.dart';
import '../presentation/case_detail_format.dart';
import 'case_detail_assets.dart';

const _initialStages = {
  'C-006': CaseStage.created,
  'C-005': CaseStage.repairScheduled,
  'mock-case-001': CaseStage.waitingResponse,
  'mock-case-002': CaseStage.responseOverdue,
  'mock-case-003': CaseStage.created,
  'mock-case-004': CaseStage.scheduling,
  'mock-case-005': CaseStage.resolved,
  'mock-case-006': CaseStage.recurred,
};

CaseStage initialStageFor(String caseId) =>
    _initialStages[caseId] ?? CaseStage.created;

const _updateStatus = StatusAction(
  'Update status',
  StatusActionType.updateStatus,
);
const _gotReply = StatusAction(
  'Got a Reply? Update Status',
  StatusActionType.updateStatus,
);
const _talkToDeaver = StatusAction(
  'Talk to Deaver',
  StatusActionType.talkToDeaver,
);
const _escalate = StatusAction('Time to Escalate', StatusActionType.escalate);
const _addProgressPhotos = StatusAction(
  'Add Progress Photos',
  StatusActionType.addPhotos,
);
const _deadline = DeadlineProgress(label: '24 hours left');

DateTime _day(int month, int day) => DateTime(2026, month, day);

TimelineStepData _done(String label, [DateTime? at]) => TimelineStepData(
  label: label,
  state: TimelineStepState.completed,
  occurredAt: at,
);

TimelineStepData _now(String label, [DateTime? at]) => TimelineStepData(
  label: label,
  state: TimelineStepState.current,
  occurredAt: at,
);

TimelineStepData _alert(String label, [DateTime? at]) => TimelineStepData(
  label: label,
  state: TimelineStepState.alert,
  occurredAt: at,
);

TimelineStepData _next(String label) =>
    TimelineStepData(label: label, state: TimelineStepState.preview);

// Mock content per stage, copied from the Figma status banner frames
CaseStageContent caseStageContent(
  CaseStage stage, {
  required DateTime createdAt,
}) => switch (stage) {
  CaseStage.created => CaseStageContent(
    banner: StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusCreated,
        width: 156,
        inset: -28,
        textGap: 8,
      ),
      headline: 'Ready to notify your landlord',
      details: [CaseDetailFormat.createdLong(createdAt)],
      action: const StatusAction('Send a notice', StatusActionType.sendNotice),
    ),
    timeline: [
      TimelineStepData(
        label: 'Case\nCreated',
        state: TimelineStepState.completed,
        eventTitle: 'Case Created',
        description: 'You documented the leak in your bathroom ceiling with 2 photos and 1 video.',
        occurredAt: createdAt.add(const Duration(hours: 10, minutes: 12)),
      ),
      const TimelineStepData(
        label: 'Notified\nLandlord',
        state: TimelineStepState.current,
        eventTitle: 'Landlord Notified',
        description: 'Sent by text to John Smith (Landlord). Included the issue, location, date first noticed and evidence.',
      ),
      const TimelineStepData(
        label: 'Waiting for\nLandlord’s Response',
        state: TimelineStepState.upcoming,
      ),
    ],
    checklist: const [
      'Send written notice to your landlord',
      'Take timestamped photos of the issue',
      'Note when it’s getting worse',
    ],
  ),
  CaseStage.waitingResponse => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusWaiting,
        width: 68,
      ),
      headline: 'Waiting for your landlord’s response',
      details: [
        'Notice sent September 28th, 3:00 PM',
        'Response due September 29th, 3:00 PM',
      ],
      action: _gotReply,
      deadline: _deadline,
    ),
    timeline: [
      _done('Case\nCreated', _day(9, 28)),
      _done('Notified\nLandlord', _day(9, 28)),
      _now('Waiting for\nLandlord’s Response'),
      _next('Follow\nUp'),
    ],
    checklist: const [
      'Check email/texts for a reply (incl. spam)',
      'Don’t attempt repairs yourself yet',
      'Log any calls or in-person talks',
      'Add new photos if it gets worse',
    ],
  ),
  CaseStage.responseOverdue => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusOverdue,
        width: 156,
        inset: -20,
      ),
      headline: 'D +1   Did you get a reply?',
      details: ['Notice sent September 28th, 3:00 PM'],
      action: _updateStatus,
    ),
    timeline: [
      _done('Case\nCreated', _day(9, 28)),
      _done('Notified\nLandlord', _day(9, 28)),
      _alert('Response\nOverdue', _day(9, 29)),
      _next('Follow\nUp'),
    ],
    checklist: const [
      'Get ready to send a follow-up',
      'Take updated photos showing it’s ongoing',
      'Log any calls or in-person talks',
      'Getting worse fast? Check with Deaver',
    ],
  ),
  CaseStage.scheduling => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusScheduling,
        width: 148,
        inset: -28,
        fillHeight: true,
      ),
      headline: 'Setting up a repair date',
      details: ['Talking with landlord since September 28th'],
      action: _updateStatus,
      illustrationAtStart: true,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('Notified\nLandlord', _day(9, 28)),
      _done('Landlord\nReplied', _day(9, 28)),
      _now('Scheduling'),
    ],
    checklist: const [
      'Offer 2–3 specific time slots in writing',
      'Ask who’s coming (company, name, contact)',
      'Ask what exactly will be fixed',
      'Set a deadline to confirm a date',
    ],
  ),
  CaseStage.followUpWaiting => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusWaiting,
        width: 68,
      ),
      headline: 'Waiting for your landlord’s response',
      details: [
        'Follow-up sent September 28th, 3:00 PM',
        'Response due September 29th, 3:00 PM',
      ],
      action: _gotReply,
      deadline: _deadline,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _alert('No\nResponse', _day(9, 29)),
      _done('Follow-up\nSent', _day(9, 29)),
      _now('Waiting for\nLandlord’s Response'),
    ],
    checklist: const [
      'Keep the first notice and follow-up together',
      'Add evidence of any delays or excuses',
      'Look up your building on HPD Online',
      'Prepare 311 complaint info just in case',
    ],
  ),
  CaseStage.followUpOverdue => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusFollowUpOverdue,
        width: 172,
        inset: -40,
      ),
      headline: 'Still no response',
      details: ['Follow-up sent September 28th, 3:00 PM', '8 hours past due'],
      action: _talkToDeaver,
      illustrationAtStart: true,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('No\nResponse', _day(9, 29)),
      _done('Follow-up\nSent', _day(9, 29)),
      _alert('Still no\nResponse', _day(9, 30)),
      _next('Filed\n311'),
    ],
    checklist: const [
      'Confirm no reply by phone or in person',
      'Review your timeline with Deaver',
      'Get ready to file a 311 complaint',
      'Consider contacting a tenant group',
    ],
  ),
  CaseStage.repairScheduled => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusRepairScheduled,
        width: 164,
        inset: -44,
      ),
      headline: 'D-3  Waiting for Repair',
      details: ['Scheduled Oct 8th, 10:00 AM – 12:00 PM'],
      action: StatusAction('Add to calendar', StatusActionType.addToCalendar),
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('Landlord\nReplied', _day(9, 28)),
      _done('Repair\nScheduled', _day(10, 1)),
      _now('Waiting for\nRepair'),
    ],
    checklist: const [
      'Confirm visit details in writing',
      'Clear access to the problem area',
      'Plan to be home (or arrange access)',
      'Write down questions for the technician',
    ],
  ),
  CaseStage.repairDay => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusRepairDay,
        width: 132,
        inset: -4,
      ),
      headline: 'Repair D-Day',
      details: ['Scheduled Today, 10:00 AM – 12:00 PM'],
      action: StatusAction(
        'Add before & after photos',
        StatusActionType.addPhotos,
      ),
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('Landlord\nReplied', _day(9, 28)),
      _done('Repair\nScheduled', _day(10, 1)),
      _now('Repair\nDay'),
    ],
    checklist: const [
      'Ask about the cause and fix, in writing if possible',
      'Ask if it’s a permanent fix or a temporary patch',
      'Get the technician’s work report',
      'Test it before they leave',
    ],
  ),
  CaseStage.repairInProgress => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusRepairInProgress,
        width: 176,
        inset: -32,
      ),
      headline: 'Repair in Progress',
      details: [
        'Visited Oct 8th, 2026 11 AM',
        'Next visit Oct 12th, 2026 10 AM',
      ],
      action: _addProgressPhotos,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('Repair\nScheduled', _day(10, 1)),
      _done('1st Visit', _day(10, 8)),
      _now('Next Visit', _day(10, 12)),
    ],
    checklist: const [
      'Ask what’s left and why',
      'Get the next visit date in writing',
      'Photograph progress after each visit',
      'Ask for a temporary fix in the meantime',
    ],
  ),
  CaseStage.landlordRefused => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusRefused,
        width: 136,
        inset: -28,
      ),
      headline: 'Landlord isn’t fixing it',
      details: [
        'Notice sent Sep 28th · 7 days, no repair',
        'Follow-up sent Sep 29th · 8 days, no repair',
      ],
      action: _escalate,
      tone: StatusTone.alert,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('No\nResponse', _day(9, 29)),
      _done('Follow-up\nSent', _day(9, 29)),
      _alert('Landlord\nRefused', _day(9, 30)),
      _next('Filed\n311'),
    ],
    checklist: const [
      'Put every notice and reply into one timeline',
      'File a 311 complaint',
      'Keep paying rent and save records',
      'Reach out to a tenant group or legal aid',
    ],
  ),
  CaseStage.blameShifting => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusBlameShifting,
        width: 140,
      ),
      headline: 'Landlord says it’s your fault',
      details: ['Claim received Oct 4th, 2026'],
      action: _escalate,
      tone: StatusTone.alert,
    ),
    timeline: [
      _done('Case\nCreated', _day(9, 28)),
      _done('Notified\nLandlord', _day(9, 28)),
      _alert('Landlord\nBlame Shifting', _day(10, 4)),
      _next('Filed\n311'),
    ],
    checklist: const [
      'Don’t admit fault in writing',
      'Show when it started and when you notified',
      'Ask for their basis in writing',
      'Check your renter’s insurance coverage',
    ],
  ),
  CaseStage.reported311 => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusReported311,
        width: 156,
        inset: -20,
        lift: 4,
      ),
      headline: 'Reported to 311',
      details: ['Complaint #311-12345678 · filed Oct 5th'],
      action: _talkToDeaver,
      tone: StatusTone.alert,
      illustrationAtStart: true,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('No\nResponse', _day(9, 29)),
      _done('Follow-up\nSent', _day(9, 29)),
      _now('311\nFiled'),
      _next('HPD\nInspection'),
    ],
    checklist: const [
      'Save your SR number',
      'Track the status in the 311 app',
      'Keep documenting the issue',
      'Tell your landlord a complaint was filed',
    ],
  ),
  CaseStage.hpdInspection => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusHpdInspection,
        width: 156,
        inset: -12,
        lift: 4,
      ),
      headline: 'HPD inspection scheduled',
      details: ['Inspection Oct 10th, 9:00 AM – 1:00 PM'],
      action: _talkToDeaver,
      tone: StatusTone.alert,
      illustrationAtStart: true,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('Follow-up\nSent', _day(9, 29)),
      _done('311\nFiled', _day(10, 5)),
      _now('HPD\nInspection'),
      _next('Notice of\nViolation'),
    ],
    checklist: const [
      'Be home to give access',
      'Have photos and your timeline ready',
      'Note the inspector’s name',
      'Ask about next steps after inspection',
    ],
  ),
  CaseStage.violationIssued => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusReported311,
        width: 156,
        inset: -20,
        lift: 4,
      ),
      headline: 'Violation issued, still not fixed',
      details: ['Violation #12345678 · issued Oct 12th'],
      action: _talkToDeaver,
      tone: StatusTone.alert,
      illustrationAtStart: true,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('311\nFiled', _day(10, 5)),
      _done('HPD\nInspection', _day(10, 10)),
      _alert('Violation\nIssued', _day(10, 12)),
    ],
    checklist: const [
      'Check the correction deadline on HPD Online',
      'Keep documenting that it’s not fixed',
      'Ask Deaver about an HP Action',
      'Contact legal aid for help',
    ],
  ),
  CaseStage.resolved => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusResolved,
        width: 148,
      ),
      headline: 'Resolved',
      details: ['Resolved Oct 20th, 2026'],
      action: StatusAction('Save case report', StatusActionType.saveReport),
      tone: StatusTone.success,
      illustrationAtStart: true,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('Landlord\nReplied', _day(9, 28)),
      _done('Repair\nScheduled', _day(10, 8)),
      _done('Repaired', _day(10, 15)),
      _now('Resolved'),
    ],
    checklist: const [
      'Take “after” photos',
      'Keep the work report and receipts',
      'Recheck in 1–2 weeks',
      'Damaged belongings? Start an insurance claim',
    ],
  ),
  CaseStage.recurred => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusRecurred,
        width: 184,
        inset: -28,
        lift: 4,
      ),
      headline: 'The problem recurred',
      details: ['Resolved Oct 11th, 2026', 'Recurred Nov 12th, 2026'],
      action: StatusAction('Trace with Deaver', StatusActionType.talkToDeaver),
      tone: StatusTone.recurring,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('Repaired', _day(10, 15)),
      _done('Resolved', _day(10, 15)),
      _now('Recurred'),
    ],
    checklist: const [
      'Record when and how it recurred',
      'Link to the previous case',
      'Ask for a root-cause fix, not a patch',
      'Recurring issues strengthen a 311 complaint',
    ],
  ),
  CaseStage.selfRepair => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusSelfRepair,
        width: 160,
      ),
      headline: 'Repairing it yourself',
      details: ['Repair Oct 8th, 2026', 'Landlord notified Oct 5th, 2026'],
      action: _addProgressPhotos,
      illustrationAtStart: true,
    ),
    timeline: [
      _done('Case\nCreated', _day(9, 28)),
      _done('Notified\nLandlord', _day(9, 28)),
      _now('Repairing\nMyself'),
    ],
    checklist: const [
      'Take before photos if you haven’t yet',
      'Keep any damaged parts as evidence',
      'Save quotes, invoices, and receipts',
      'Write down why it couldn’t wait',
    ],
  ),
  CaseStage.repairCostClaim => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusRepairCostClaim,
        width: 156,
        inset: -16,
      ),
      headline: 'Filing a claim',
      details: ['Claim sent to landlord Oct 11th, 2026'],
      action: StatusAction('Send a Claim', StatusActionType.sendClaim),
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('Notified\nLandlord', _day(9, 28)),
      _done('Repairing\nMyself', _day(9, 28)),
      _now('Claim Sent'),
    ],
    checklist: const [
      'Add before & after photos',
      'Attach invoices and receipts',
      'Set a deadline for payment in writing',
      'Don’t deduct from rent without legal advice',
    ],
  ),
  CaseStage.insuranceClaim => CaseStageContent(
    banner: const StatusBanner(
      illustration: BannerIllustration(
        CaseDetailAssets.statusInsuranceClaim,
        width: 156,
        inset: -36,
      ),
      headline: 'Filing an insurance claim',
      details: ['Claim filed with insurance Oct 11th, 2026'],
      action: _updateStatus,
    ),
    timelineHasEarlierSteps: true,
    timeline: [
      _done('Notified\nLandlord', _day(9, 28)),
      _done('Repairing\nMyself', _day(9, 28)),
      _now('Claim Filed'),
    ],
    checklist: const [
      'List damaged items with photos and value',
      'Get the repair report as proof of cause',
      'Check your policy’s deadline and deductible',
      'Save your claim number',
    ],
  ),
};
