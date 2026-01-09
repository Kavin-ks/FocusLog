import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool showDivider;

  const SectionHeader({super.key, required this.title, this.trailing, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Divider(height: 1, color: AppTheme.muted.withAlpha(40)),
        ],
      ],
    );
  }
}
