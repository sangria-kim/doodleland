enum MotionPreset { floating, bouncing, gliding, rolling, fluttering }

extension MotionPresetText on MotionPreset {
  String get label {
    return switch (this) {
      MotionPreset.floating => '둥실둥실',
      MotionPreset.bouncing => '통통 점프',
      MotionPreset.gliding => '씽씽 활공',
      MotionPreset.rolling => '데굴데굴',
      MotionPreset.fluttering => '나풀나풀',
    };
  }

  String get description {
    return switch (this) {
      MotionPreset.floating => '천천히 위아래로 떠다니는 기본 움직임',
      MotionPreset.bouncing => '짧은 주기로 경쾌하게 튀어오르는 움직임',
      MotionPreset.gliding =>
          '상승-급강하를 반복해 활공하는 비행체 같은 움직임',
      MotionPreset.rolling => '제자리에서 굴러가듯 회전하는 모션',
      MotionPreset.fluttering =>
          '위에서 천천히 떨어지며 좌우로 흔들리는 나풀나풀하는 움직임',
    };
  }
}
