import 'package:equatable/equatable.dart';

/// The user's notification opt-ins.
///
/// A single [master] switch gates delivery entirely; the granular categories
/// let the user tune what they receive. Each `effective*` getter answers the
/// real question the app asks ("should I deliver a job alert?") by AND-ing the
/// category with the master toggle. Architecture-ready for wiring to FCM topic
/// subscription later.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.master = true,
    this.jobAlerts = true,
    this.applicationUpdates = true,
    this.coachTips = true,
  });

  final bool master;
  final bool jobAlerts;
  final bool applicationUpdates;
  final bool coachTips;

  bool get effectiveJobAlerts => master && jobAlerts;
  bool get effectiveApplicationUpdates => master && applicationUpdates;
  bool get effectiveCoachTips => master && coachTips;

  NotificationPreferences copyWith({
    bool? master,
    bool? jobAlerts,
    bool? applicationUpdates,
    bool? coachTips,
  }) {
    return NotificationPreferences(
      master: master ?? this.master,
      jobAlerts: jobAlerts ?? this.jobAlerts,
      applicationUpdates: applicationUpdates ?? this.applicationUpdates,
      coachTips: coachTips ?? this.coachTips,
    );
  }

  @override
  List<Object?> get props =>
      [master, jobAlerts, applicationUpdates, coachTips];
}
