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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: MotionPreset.values
          .map(
            (motion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceChip(
                label: Text(motion.label),
                selected: selectedMotion == motion,
                onSelected: (_) => onChanged(motion),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
