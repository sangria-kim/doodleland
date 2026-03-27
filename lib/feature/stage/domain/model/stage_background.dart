import 'package:flutter/foundation.dart';

@immutable
class StageBackground {
  const StageBackground({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.groundY,
  });

  final String id;
  final String name;
  final String assetPath;
  final double groundY;
}

const List<StageBackground> defaultStageBackgrounds = [
  StageBackground(
    id: 'forest',
    name: '숲',
    assetPath: 'assets/backgrounds/forest.png',
    groundY: 0.86,
  ),
  StageBackground(
    id: 'sky',
    name: '푸른 하늘',
    assetPath: 'assets/backgrounds/sky.png',
    groundY: 0.84,
  ),
  StageBackground(
    id: 'ocean',
    name: '바다',
    assetPath: 'assets/backgrounds/ocean.png',
    groundY: 0.81,
  ),
  StageBackground(
    id: 'starry_night',
    name: '별빛 밤',
    assetPath: 'assets/backgrounds/starry_night.png',
    groundY: 0.83,
  ),
  StageBackground(
    id: 'candy_land',
    name: '캔디 랜드',
    assetPath: 'assets/backgrounds/candy_land.png',
    groundY: 0.88,
  ),
];
