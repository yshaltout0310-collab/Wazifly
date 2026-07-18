import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';

/// Lightweight responsive helpers.
///
/// Wazifly targets phones and tablets, so layouts read these to adapt
/// padding and width instead of hard-coding sizes.
extension ResponsiveContext on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);

  double get screenWidth => _size.width;
  double get screenHeight => _size.height;

  bool get isTablet => screenWidth >= AppConstants.tabletBreakpoint;

  /// Horizontal padding that grows on larger screens.
  double get horizontalGutter => isTablet ? 40 : 24;

  /// Caps body content width so text/cards don't stretch on tablets.
  double get contentWidth =>
      screenWidth > AppConstants.maxContentWidth
          ? AppConstants.maxContentWidth
          : screenWidth;
}

/// Centers and width-constrains its child for comfortable reading on tablets.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    required this.child,
    this.maxWidth = AppConstants.maxContentWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
