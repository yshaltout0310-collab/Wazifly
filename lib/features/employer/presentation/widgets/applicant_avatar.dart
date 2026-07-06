import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A circular applicant avatar — the photo when available, otherwise the initial
/// on a branded background.
class ApplicantAvatar extends StatelessWidget {
  const ApplicantAvatar({
    required this.name,
    this.photoUrl,
    this.radius = 22,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (photoUrl ?? '').isNotEmpty;
    final initial =
        name.trim().isNotEmpty ? name.trim().characters.first.toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w800,
                color: AppColors.emeraldDark,
              ),
            ),
    );
  }
}
