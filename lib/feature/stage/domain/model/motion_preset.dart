enum MotionPreset {
  floating,
  bouncing,
  gliding,
  rolling,
  spinning,
}

extension MotionPresetText on MotionPreset {
  String get label {
    return switch (this) {
      MotionPreset.floating => '둥실둥실',
      MotionPreset.bouncing => '통통 점프',
      MotionPreset.gliding => '씽씽 활공',
      MotionPreset.rolling => '데굴데굴',
      MotionPreset.spinning => '빙글빙글',
    };
  }

  String get description {
    return switch (this) {
      MotionPreset.floating => '천천히 위아래로 떠다니는 기본 움직임',
      MotionPreset.bouncing => '짧은 주기로 경쾌하게 튀어오르는 움직임',
      MotionPreset.gliding => '좌우로 왕복하는 활공 움직임',
      MotionPreset.rolling => '회전하면서 좌우로 움직이는 굴러가는 모션',
      MotionPreset.spinning => '그 자리에 서서 회전하는 모션',
    };
  }
}
