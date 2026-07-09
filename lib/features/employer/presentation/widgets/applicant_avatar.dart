import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_network_image.dart';

/// A circular applicant avatar — the (decode-downsized) photo when available,
/// otherwise the initial on a branded background. If the photo fails to load it
/// degrades to the initial rather than showing an empty circle.
class ApplicantAvatar extends StatefulWidget {
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
  State<ApplicantAvatar> createState() => _ApplicantAvatarState();
}

class _ApplicantAvatarState extends State<ApplicantAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(covariant ApplicantAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.photoUrl ?? '';
    final showPhoto = url.isNotEmpty && !_failed;
    final initial = widget.name.trim().isNotEmpty
        ? widget.name.trim().characters.first.toUpperCase()
        : '?';
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
      backgroundImage: showPhoto
          ? AppImage.provider(url,
              context: context, logicalSize: widget.radius * 2)
          : null,
      onBackgroundImageError: showPhoto
          ? (_, __) {
              if (mounted) setState(() => _failed = true);
            }
          : null,
      child: showPhoto
          ? null
          : Text(
              initial,
              style: TextStyle(
                fontSize: widget.radius * 0.8,
                fontWeight: FontWeight.w800,
                color: AppColors.emeraldDark,
              ),
            ),
    );
  }
}
