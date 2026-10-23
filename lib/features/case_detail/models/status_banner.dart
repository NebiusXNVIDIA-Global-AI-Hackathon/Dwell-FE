enum StatusTone { notice, alert, recurring, success }

enum StatusActionType {
  sendNotice,
  updateStatus,
  talkToDeaver,
  addToCalendar,
  addPhotos,
  escalate,
  saveReport,
  sendClaim,
}

class StatusAction {
  const StatusAction(this.label, this.type);

  final String label;
  final StatusActionType type;
}

class DeadlineProgress {
  const DeadlineProgress({required this.label, this.elapsed = 0});

  final String label;
  final double elapsed;
}

/// Bottom-anchored illustration; a negative inset crops it at the outer edge.
class BannerIllustration {
  const BannerIllustration(
    this.path, {
    required this.width,
    this.inset = 0,
    this.fillHeight = false,
    this.textGap = 16,
    this.lift = 0,
  });

  final String path;
  final double width;
  final double inset;
  final bool fillHeight;
  final double textGap;
  final double lift;

  double get extent => width + inset;
}

class StatusBanner {
  const StatusBanner({
    required this.headline,
    required this.details,
    required this.action,
    this.tone = StatusTone.notice,
    this.illustrationAtStart = false,
    this.deadline,
    this.illustration,
  });

  final String headline;
  final List<String> details;
  final StatusAction action;
  final StatusTone tone;
  final bool illustrationAtStart;
  final DeadlineProgress? deadline;
  final BannerIllustration? illustration;
}
