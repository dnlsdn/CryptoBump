import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final String? caption;
  final Widget? trailing;
  final List<Widget> children;

  const SectionCard({super.key, this.title, this.caption, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onSurfaceSubtle = Theme.of(context).colorScheme.onSurface.withOpacity(.6);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || trailing != null)
              Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(title!, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            if (caption != null) ...[
              const SizedBox(height: 6),
              Text(caption!, style: text.bodySmall?.copyWith(color: onSurfaceSubtle)),
            ],
            if (title != null || caption != null) const SizedBox(height: 12),
            ..._withSpacing(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> items) {
    return [
      for (int i = 0; i < items.length; i++) ...[items[i], if (i != items.length - 1) const SizedBox(height: 12)],
    ];
  }
}
