import 'package:equatable/equatable.dart';

/// At-a-glance recruiting metrics for the Employer Home dashboard.
///
/// Milestone 1 shows all zeros ([CompanyStats.zero]) via a provider that later
/// milestones rebind to derive from the jobs / applications repositories — the
/// dashboard widgets need no change when the numbers become real.
class CompanyStats extends Equatable {
  const CompanyStats({
    this.activeJobs = 0,
    this.applications = 0,
    this.interviews = 0,
    this.hires = 0,
  });

  final int activeJobs;
  final int applications;
  final int interviews;
  final int hires;

  static const CompanyStats zero = CompanyStats();

  @override
  List<Object?> get props => [activeJobs, applications, interviews, hires];
}
