import 'package:flutter/material.dart';

import '../../../stage/domain/model/motion_preset.dart';

class MotionSelector extends StatelessWidget {
  const MotionSelector({
    super.key,
    required this.selectedMotion,
    required this.onChanged,
  });

  final MotionPreset selectedMotion;
  final ValueChanged<MotionPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final isWide = constraints.maxWidth >= 520;
        final itemWidth = isWide
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: MotionPreset.values
              .map(
                (motion) => SizedBox(
                  width: itemWidth,
                  child: _MotionOptionCard(
                    motion: motion,
                    selected: selectedMotion == motion,
                    onTap: () => onChanged(motion),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _MotionOptionCard extends StatelessWidget {
  const _MotionOptionCard({
    required this.motion,
    required this.selected,
    required this.onTap,
  });

  final MotionPreset motion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.outlineVariant;
    final backgroundColor = selected
        ? colorScheme.primaryContainer
        : colorScheme.surface;
    final accentColor = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconForMotion(motion), color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      motion.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      motion.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: accentColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForMotion(MotionPreset motion) {
  return switch (motion) {
    MotionPreset.floating => Icons.air,
    MotionPreset.bouncing => Icons.sports_basketball,
    MotionPreset.gliding => Icons.swap_horiz,
    MotionPreset.rolling => Icons.blur_circular,
    MotionPreset.spinning => Icons.refresh,
  };
}
