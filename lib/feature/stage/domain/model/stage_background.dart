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
    assetPath: 'assets/backgrounds/bg_forest.jpg',
    groundY: 0.86,
  ),
  StageBackground(
    id: 'sky',
    name: '푸른 하늘',
    assetPath: 'assets/backgrounds/bg_sky.jpg',
    groundY: 0.84,
  ),
  StageBackground(
    id: 'ocean',
    name: '바다',
    assetPath: 'assets/backgrounds/bg_ocean.jpg',
    groundY: 0.81,
  ),
  StageBackground(
    id: 'starry_night',
    name: '별빛 밤',
    assetPath: 'assets/backgrounds/bg_starry_night.jpg',
    groundY: 0.83,
  ),
  StageBackground(
    id: 'candy_land',
    name: '캔디 랜드',
    assetPath: 'assets/backgrounds/bg_candy_land.jpg',
    groundY: 0.88,
  ),
  StageBackground(
    id: 'pororo_playground',
    name: '뽀로로 놀이터',
    assetPath: 'assets/backgrounds/bg_pororo.jpg',
    groundY: 0.82,
  ),
];
