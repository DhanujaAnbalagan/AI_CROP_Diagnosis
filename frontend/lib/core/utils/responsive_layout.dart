import 'package:flutter/material.dart';

/// Responsive breakpoints for the app.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
}

/// Returns responsive padding based on screen width.
EdgeInsets responsivePadding(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= Breakpoints.tablet) return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
  if (w >= Breakpoints.mobile) return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
  return const EdgeInsets.all(16);
}

/// Returns responsive max-width for content.
double responsiveMaxWidth(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= Breakpoints.tablet) return 800;
  if (w >= Breakpoints.mobile) return 680;
  return double.infinity;
}

/// Returns responsive grid column count.
int responsiveColumns(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
  final w = MediaQuery.of(context).size.width;
  if (w >= Breakpoints.tablet) return desktop;
  if (w >= Breakpoints.mobile) return tablet;
  return mobile;
}

/// Wraps content in a responsive centered container.
/// Use this as the body child for inner pages.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsiveBody({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: responsiveMaxWidth(context)),
        child: Padding(
          padding: padding ?? responsivePadding(context),
          child: child,
        ),
      ),
    );
  }
}
