import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CardSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CardSurface({super.key, required this.child, this.padding = const EdgeInsets.all(AppTheme.spacingMd)});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTheme.cardElevation,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
