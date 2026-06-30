import 'package:flutter/material.dart';

/// View model for a single onboarding page.
class OnboardingPage {
  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    this.features = const [],
  });

  final IconData icon;
  final String title;
  final String body;

  /// Optional bullet features (used on the AI page).
  final List<({IconData icon, String label})> features;
}
