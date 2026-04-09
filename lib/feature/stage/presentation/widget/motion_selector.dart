import 'package:flutter/material.dart';

import '../../../stage/domain/model/motion_preset.dart';

class MotionSelector extends StatelessWidget {
  const MotionSelector({
    super.key,
    required this.selectedMotion,
    required this.onChanged,
    this.compact = false,
  });

  final MotionPreset selectedMotion;
  final ValueChanged<MotionPreset> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final estimatedHeight = constraints.maxWidth >= 520
            ? (compact ? 68.0 : 84.0)
            : (compact ? 62.0 : 74.0);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: MotionPreset.values.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: estimatedHeight,
          ),
          itemBuilder: (context, index) {
            final motion = MotionPreset.values[index];
            return _MotionOptionCard(
              motion: motion,
              selected: selectedMotion == motion,
              onTap: () => onChanged(motion),
              compact: compact,
            );
          },
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
    required this.compact,
  });

  final MotionPreset motion;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

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
          constraints: BoxConstraints(minHeight: compact ? 68 : 0),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 10 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Icon(_iconForMotion(motion), color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: compact
                    ? Text(
                        motion.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Column(
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
                size: compact ? 20 : 22,
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
    MotionPreset.fluttering => Icons.grain,
  };
}
