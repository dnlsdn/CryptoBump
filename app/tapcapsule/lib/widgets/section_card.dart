import 'package:flutter/material.dart';
import '../ui/theme.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final String? caption;
  final Widget? trailing;
  final List<Widget> children;
  final bool highlight;

  const SectionCard({
    super.key,
    this.title,
    this.caption,
    this.trailing,
    required this.children,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onSurfaceSubtle = AppTheme.lightText.withOpacity(.6);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withOpacity(0.1),
                  AppTheme.secondary.withOpacity(0.05),
                ],
              )
            : null,
        color: highlight ? null : AppTheme.darkCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight
              ? AppTheme.primary.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? AppTheme.primary.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || trailing != null)
              Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.lightText,
                        ),
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            if (caption != null) ...[
              const SizedBox(height: 8),
              Text(
                caption!,
                style: text.bodyMedium?.copyWith(color: onSurfaceSubtle),
              ),
            ],
            if (title != null || caption != null) const SizedBox(height: 16),
            ..._withSpacing(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> items) {
    return [
      for (int i = 0; i < items.length; i++) ...[
        items[i],
        if (i != items.length - 1) const SizedBox(height: 16)
      ],
    ];
  }
}
