import '../../../core/database/app_database.dart';
import '../domain/model/motion_preset.dart';

class CharacterPlacementSelection {
  const CharacterPlacementSelection({
    required this.character,
    required this.objectMotion,
  });

  final Character character;
  final MotionPreset objectMotion;
}
