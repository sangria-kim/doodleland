import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/model/placed_character.dart';
import '../domain/model/motion_preset.dart';
import '../domain/model/stage_motion.dart';
import '../domain/model/stage_motion_engine.dart';
import 'stage_viewmodel.dart';
import 'widget/character_selector.dart';

class _StageEffectConfig {
  static const int entranceDurationMs = 800;
  static const double entranceStartScale = 0.5;
  static const double entranceOvershootScale = 1.5;
  static const double entranceEndScale = 1.0;

  static const int removeDurationMs = 1000;
  static const double removeTranslateStartY = 0.0;
  static const double removeTranslateAnticipationY = 8.0;
  static const double removeTranslateEndY = -36.0;
  static const double removeHorizontalTravelPx = 12.0;
  static const double removeScaleStart = 1.0;
  static const double removeScalePop = 1.08;
  static const double removeScaleEnd = 0.58;
  static const double removeRotationRadians = 0.16;
  static const double removeOpacityStart = 1.0;
  static const double removeOpacityEnd = 0.0;

  static const int confettiCount = 28;
  static const double confettiMinSize = 3.0;
  static const double confettiMaxSize = 6.0;
  static const int confettiMinDurationMs = 800;
  static const int confettiMaxDurationMs = 800;
  static const double confettiDriftRange = 34.0;
  static const double confettiSpawnAreaWidth = 210.0;

  static const List<Color> confettiColorPalette = [
    Color(0xFFE84A5F),
    Color(0xFFFFC857),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFF9B5DE5),
    Color(0xFFFF66C4),
    Color(0xFFFF8C42),
  ];
}

@immutable
class _ConfettiBurstRequest {
  const _ConfettiBurstRequest({
    required this.id,
    required this.normalizedX,
    required this.normalizedY,
    required this.objectWidth,
    required this.objectHeight,
    required this.count,
  });

  final int id;
  final double normalizedX;
  final double normalizedY;
  final double objectWidth;
  final double objectHeight;
  final int count;
}

class StageScreen extends ConsumerStatefulWidget {
  const StageScreen({super.key});

  @override
  ConsumerState<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends ConsumerState<StageScreen> {
  static const Duration _controlHideDelay = Duration(seconds: 2);

  bool _showControls = true;
  Timer? _controlTimer;
  final Set<String> _pendingEntranceInstanceIds = <String>{};
  final List<_ConfettiBurstRequest> _pendingConfettiBursts =
      <_ConfettiBurstRequest>[];
  int _nextConfettiBurstId = 1;

  @override
  void dispose() {
    _controlTimer?.cancel();
    super.dispose();
  }

  void _showControlsForAWhile() {
    setState(() {
      _showControls = true;
    });
    _controlTimer?.cancel();
    _controlTimer = Timer(_controlHideDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showControls = false;
      });
    });
  }

  void _onStageStateChanged(StageState? previous, StageState next) {
    if (!mounted || previous == null) {
      return;
    }

    final previousIds = previous.placedCharacters
        .map((character) => character.instanceId)
        .toSet();
    final nextIds = next.placedCharacters
        .map((character) => character.instanceId)
        .toSet();
    final staleEntranceIds = _pendingEntranceInstanceIds
        .difference(nextIds)
        .toSet();
    final addedCharacters = next.placedCharacters
        .where((character) => !previousIds.contains(character.instanceId))
        .toList(growable: false);

    if (addedCharacters.isEmpty && staleEntranceIds.isEmpty) {
      return;
    }

    setState(() {
      _pendingEntranceInstanceIds.removeAll(staleEntranceIds);
      for (final character in addedCharacters) {
        final objectSize = _characterDisplaySize(character);
        _pendingEntranceInstanceIds.add(character.instanceId);
        _pendingConfettiBursts.add(
          _ConfettiBurstRequest(
            id: _nextConfettiBurstId++,
            normalizedX: character.position.dx.clamp(0.08, 0.92).toDouble(),
            normalizedY: character.position.dy.clamp(0.08, 0.92).toDouble(),
            objectWidth: objectSize.width,
            objectHeight: objectSize.height,
            count: _adaptiveConfettiCount(),
          ),
        );
      }
    });
  }

  int _adaptiveConfettiCount() {
    final burstLoad = _pendingConfettiBursts.length;
    final reduced = _StageEffectConfig.confettiCount - burstLoad * 4;
    return reduced.clamp(14, _StageEffectConfig.confettiCount).toInt();
  }

  void _handleEntranceCompleted(String instanceId) {
    if (!_pendingEntranceInstanceIds.contains(instanceId)) {
      return;
    }
    setState(() {
      _pendingEntranceInstanceIds.remove(instanceId);
    });
  }

  void _handleConfettiBurstsConsumed(Set<int> consumedIds) {
    if (consumedIds.isEmpty) {
      return;
    }
    setState(() {
      _pendingConfettiBursts.removeWhere(
        (request) => consumedIds.contains(request.id),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StageState>(stageViewModelProvider, _onStageStateChanged);
    final state = ref.watch(stageViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.of(context).padding.top;
          final horizontalPadding = 16.0;
          final overlayColor = Colors.black.withValues(alpha: 0.36);
          final overlayDecoration = BoxDecoration(
            color: overlayColor,
            borderRadius: BorderRadius.circular(18),
          );
          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showControlsForAWhile,
                onPanDown: (_) => _showControlsForAWhile(),
                child: Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(state.selectedBackground.assetPath),
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                  child: state.placedCharacters.isEmpty
                      ? _EmptyStageHint()
                      : _PlacedCharactersStage(
                          placedCharacters: state.placedCharacters,
                          stageSize: constraints.biggest,
                          onInteraction: _showControlsForAWhile,
                          onBringToFront: (instanceId) {
                            ref
                                .read(stageViewModelProvider.notifier)
                                .bringCharacterToFront(instanceId);
                          },
                          onMove: (instanceId, position) {
                            ref
                                .read(stageViewModelProvider.notifier)
                                .updateCharacterPosition(
                                  instanceId: instanceId,
                                  position: position,
                                );
                          },
                          onDelete: (instanceId) async {
                            final started = ref
                                .read(stageViewModelProvider.notifier)
                                .requestCharacterRemoval(instanceId);

                            if (context.mounted) {
                              final message = started
                                  ? '무대에서 제거 중이에요.'
                                  : '제거하지 못했어요.';
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(message)));
                            }
                          },
                          onRemoveAnimationCompleted: (instanceId) {
                            ref
                                .read(stageViewModelProvider.notifier)
                                .completeCharacterRemoval(instanceId);
                          },
                          pendingEntranceInstanceIds:
                              _pendingEntranceInstanceIds,
                          onEntranceCompleted: _handleEntranceCompleted,
                        ),
                ),
              ),
              Positioned.fill(
                child: _ConfettiEffectOverlay(
                  bursts: _pendingConfettiBursts,
                  onBurstsCompleted: _handleConfettiBurstsConsumed,
                ),
              ),
              Positioned(
                left: horizontalPadding,
                right: horizontalPadding,
                top: topPadding + 12,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1 : 0,
                    duration: const Duration(milliseconds: 420),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: overlayDecoration,
                          child: IconButton(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.white,
                            tooltip: '뒤로 가기',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(40, 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: overlayDecoration,
                          child: IconButton(
                            onPressed: () => context.go('/stage/background'),
                            icon: const Icon(Icons.image),
                            color: Colors.white,
                            tooltip: '배경 바꾸기',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(40, 40),
                            ),
                          ),
                        ),
                        const Spacer(),
                        DecoratedBox(
                          decoration: overlayDecoration,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              '${state.placedCharacters.length}/10',
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ) ??
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (state.errorMessage != null)
                Positioned(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: topPadding + 64,
                  child: Card(
                    color: Colors.red.shade50.withValues(alpha: 0.9),
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(state.errorMessage!),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: ref
                            .read(stageViewModelProvider.notifier)
                            .clearError,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: IgnorePointer(
        ignoring: !_showControls,
        child: AnimatedOpacity(
          opacity: _showControls ? 1 : 0,
          duration: const Duration(milliseconds: 420),
          child: Tooltip(
            message: state.isFull ? '무대가 꽉 찼어요!' : '그림 추가',
            child: FloatingActionButton(
              onPressed: state.isFull
                  ? null
                  : () {
                      _showControlsForAWhile();
                      _openCharacterSelector(context);
                    },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCharacterSelector(BuildContext context) async {
    final selection = await context.push<CharacterPlacementSelection>(
      '/stage/character-placement',
    );

    if (!context.mounted || selection == null) {
      return;
    }

    final isAdded = await ref
        .read(stageViewModelProvider.notifier)
        .placeCharacter(
          character: selection.character,
          objectMotion: selection.objectMotion,
        );

    if (!context.mounted) {
      return;
    }

    final message = isAdded ? '무대에 등장했어요.' : '무대에 추가하지 못했어요.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmptyStageHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '아직 배치된 캐릭터가 없어요.\n오른쪽 아래 + 버튼을 눌러 추가해보세요.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _PlacedCharactersStage extends StatelessWidget {
  const _PlacedCharactersStage({
    required this.placedCharacters,
    required this.stageSize,
    required this.onInteraction,
    required this.onBringToFront,
    required this.onMove,
    required this.onDelete,
    required this.onRemoveAnimationCompleted,
    required this.pendingEntranceInstanceIds,
    required this.onEntranceCompleted,
  });

  final List<PlacedCharacter> placedCharacters;
  final Size stageSize;
  final VoidCallback onInteraction;
  final ValueChanged<String> onBringToFront;
  final void Function(String instanceId, Offset position) onMove;
  final Future<void> Function(String instanceId) onDelete;
  final ValueChanged<String> onRemoveAnimationCompleted;
  final Set<String> pendingEntranceInstanceIds;
  final ValueChanged<String> onEntranceCompleted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final placed in [
          ...placedCharacters,
        ]..sort((a, b) => a.zIndex.compareTo(b.zIndex)))
          _InteractivePlacedCharacter(
            key: ValueKey(placed.instanceId),
            placed: placed,
            stageSize: stageSize,
            onInteraction: onInteraction,
            onBringToFront: onBringToFront,
            onMove: onMove,
            onDelete: onDelete,
            onRemoveAnimationCompleted: onRemoveAnimationCompleted,
            shouldPlayEntrance: pendingEntranceInstanceIds.contains(
              placed.instanceId,
            ),
            onEntranceCompleted: onEntranceCompleted,
          ),
      ],
    );
  }
}

class _InteractivePlacedCharacter extends StatefulWidget {
  const _InteractivePlacedCharacter({
    super.key,
    required this.placed,
    required this.stageSize,
    required this.onInteraction,
    required this.onBringToFront,
    required this.onMove,
    required this.onDelete,
    required this.onRemoveAnimationCompleted,
    required this.shouldPlayEntrance,
    required this.onEntranceCompleted,
  });

  final PlacedCharacter placed;
  final Size stageSize;
  final VoidCallback onInteraction;
  final ValueChanged<String> onBringToFront;
  final void Function(String instanceId, Offset position) onMove;
  final Future<void> Function(String instanceId) onDelete;
  final ValueChanged<String> onRemoveAnimationCompleted;
  final bool shouldPlayEntrance;
  final ValueChanged<String> onEntranceCompleted;

  @override
  State<_InteractivePlacedCharacter> createState() =>
      _InteractivePlacedCharacterState();
}

class _InteractivePlacedCharacterState
    extends State<_InteractivePlacedCharacter>
    with TickerProviderStateMixin {
  static const StageMotionEngine _stageMotionEngine = StageMotionEngine();

  late final AnimationController _entryController;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryOpacity;
  late final AnimationController _removeController;
  late final Animation<double> _removeTranslateY;
  late final Animation<double> _removeTranslateXFactor;
  late final Animation<double> _removeScale;
  late final Animation<double> _removeRotateFactor;
  late final Animation<double> _removeOpacity;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;
  late final AnimationController _objectMotionController;
  late final Animation<double> _objectMotionPhase;
  late final Ticker _stageTicker;

  Offset _dragStartPosition = Offset.zero;
  bool _isDragging = false;
  Duration _lastTickTimestamp = Duration.zero;
  late StageMotionRuntimeState _stageRuntime;
  bool _isMotionActivated = false;
  bool _hasCharacterImageReady = false;
  bool _entranceStarted = false;
  bool _entranceCompleted = false;
  bool _isRemoving = false;
  bool _removeCompletionNotified = false;
  double _removeTranslateXEnd = 0.0;
  double _removeRotationEnd = 0.0;

  @override
  void initState() {
    super.initState();
    _stageRuntime = widget.placed.stageRuntime;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: _StageEffectConfig.entranceDurationMs,
      ),
    );
    _entryScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: _StageEffectConfig.entranceStartScale,
          end: _StageEffectConfig.entranceOvershootScale,
        ).chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: _StageEffectConfig.entranceOvershootScale,
          end: _StageEffectConfig.entranceEndScale,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
    ]).animate(_entryController);
    _entryOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.62, curve: Curves.easeOut),
    );
    _removeController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: _StageEffectConfig.removeDurationMs,
      ),
    );
    _removeTranslateY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: _StageEffectConfig.removeTranslateStartY,
          end: _StageEffectConfig.removeTranslateAnticipationY,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: _StageEffectConfig.removeTranslateAnticipationY,
          end: _StageEffectConfig.removeTranslateEndY,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 82,
      ),
    ]).animate(_removeController);
    _removeTranslateXFactor = CurvedAnimation(
      parent: _removeController,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
    );
    _removeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: _StageEffectConfig.removeScaleStart,
          end: _StageEffectConfig.removeScalePop,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: _StageEffectConfig.removeScalePop,
          end: _StageEffectConfig.removeScaleEnd,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 76,
      ),
    ]).animate(_removeController);
    _removeRotateFactor = CurvedAnimation(
      parent: _removeController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _removeOpacity =
        Tween<double>(
          begin: _StageEffectConfig.removeOpacityStart,
          end: _StageEffectConfig.removeOpacityEnd,
        ).animate(
          CurvedAnimation(
            parent: _removeController,
            curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
          ),
        );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_bounceController);
    _objectMotionController = AnimationController(
      vsync: this,
      duration: _objectMotionDuration(),
    );
    _objectMotionPhase = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _objectMotionController, curve: Curves.linear),
    );

    _stageTicker = createTicker(_onStageTick)..start();

    _isRemoving =
        widget.placed.removalState == PlacedCharacterRemovalState.removing;
    _armEntranceIfNeeded();
    if (_isRemoving) {
      _beginRemoving();
    }

    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isDragging && mounted) {
        _startObjectMotionAnimation();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _InteractivePlacedCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placed.instanceId != widget.placed.instanceId) {
      _stageRuntime = widget.placed.stageRuntime;
      _isMotionActivated = false;
      _hasCharacterImageReady = false;
      _entranceStarted = false;
      _entranceCompleted = false;
      _isRemoving = false;
      _removeCompletionNotified = false;
      _removeController.value = 0.0;
      _removeTranslateXEnd = 0.0;
      _removeRotationEnd = 0.0;
    }
    if (!oldWidget.shouldPlayEntrance && widget.shouldPlayEntrance) {
      _armEntranceIfNeeded(forceRestart: true);
    }
    if (!_isRemoving &&
        widget.placed.removalState == PlacedCharacterRemovalState.removing) {
      _beginRemoving();
    }
  }

  @override
  void dispose() {
    _stageTicker.dispose();
    _entryController.dispose();
    _removeController.dispose();
    _bounceController.dispose();
    _objectMotionController.dispose();
    super.dispose();
  }

  void _onStageTick(Duration elapsed) {
    if (!_isMotionActivated || _isRemoving) {
      _lastTickTimestamp = elapsed;
      return;
    }

    final delta = elapsed - _lastTickTimestamp;
    _lastTickTimestamp = elapsed;

    final nextRuntime = _stageMotionEngine.tick(
      motion: widget.placed.stageMotion,
      runtime: _stageRuntime,
      stageSize: widget.stageSize,
      objectSize: _characterDisplaySize(
        widget.placed,
        includePlacedScale: true,
      ),
      delta: delta,
    );

    if (!_isSameRuntime(nextRuntime, _stageRuntime) && mounted) {
      setState(() {
        _stageRuntime = nextRuntime;
      });
    }
  }

  Duration _objectMotionDuration() {
    return switch (widget.placed.objectMotion) {
      MotionPreset.floating => const Duration(milliseconds: 2000),
      MotionPreset.bouncing => const Duration(milliseconds: 1200),
      MotionPreset.gliding => const Duration(milliseconds: 3000),
      MotionPreset.rolling => const Duration(milliseconds: 2500),
    };
  }

  void _armEntranceIfNeeded({bool forceRestart = false}) {
    if (_isRemoving) {
      _isMotionActivated = false;
      _pauseObjectMotionAnimation();
      return;
    }

    if (!widget.shouldPlayEntrance) {
      _isMotionActivated = true;
      _entranceCompleted = true;
      _entranceStarted = true;
      _entryController.value = 1.0;
      _startObjectMotionAnimation();
      return;
    }

    if (_entranceCompleted && !forceRestart) {
      _entryController.value = 1.0;
      return;
    }

    _entranceCompleted = false;
    _entranceStarted = false;
    _isMotionActivated = false;
    _pauseObjectMotionAnimation();
    _entryController.value = 0.0;

    if (_hasCharacterImageReady) {
      _startEntranceAnimation();
    }
  }

  void _startEntranceAnimation() {
    if (_isRemoving ||
        !widget.shouldPlayEntrance ||
        _entranceStarted ||
        _entranceCompleted) {
      return;
    }

    _entranceStarted = true;
    _entryController.forward(from: 0.0).whenComplete(() {
      if (!mounted || _entranceCompleted) {
        return;
      }
      _entranceCompleted = true;
      _isMotionActivated = true;
      widget.onEntranceCompleted(widget.placed.instanceId);
      if (!_isDragging) {
        _startObjectMotionAnimation();
      }
    });
  }

  void _handleCharacterImageReady() {
    if (_hasCharacterImageReady) {
      return;
    }
    _hasCharacterImageReady = true;
    if (_isRemoving) {
      return;
    }
    if (widget.shouldPlayEntrance) {
      _startEntranceAnimation();
    }
  }

  void _beginRemoving() {
    if (_isRemoving && _removeController.isAnimating) {
      return;
    }

    _isRemoving = true;
    _isMotionActivated = false;
    _isDragging = false;
    _dragStartPosition = _stageRuntime.position;
    _stageRuntime = _stageRuntime.copyWith(isPaused: true);
    final removeDirectionSign =
        _stageRuntime.direction == StageMotionDirection.leftToRight
        ? 1.0
        : -1.0;
    _removeTranslateXEnd =
        _StageEffectConfig.removeHorizontalTravelPx * removeDirectionSign;
    _removeRotationEnd =
        _StageEffectConfig.removeRotationRadians * removeDirectionSign;

    _entryController.stop();
    _entryController.value = 1.0;
    _bounceController.stop();
    _bounceController.value = 0.0;
    _pauseObjectMotionAnimation();

    _removeController.forward(from: 0.0).whenComplete(() {
      if (!mounted || _removeCompletionNotified) {
        return;
      }
      _removeCompletionNotified = true;
      widget.onRemoveAnimationCompleted(widget.placed.instanceId);
    });
  }

  void _startObjectMotionAnimation() {
    if (_isRemoving || _isDragging || !_isMotionActivated) {
      return;
    }
    if (!_objectMotionController.isAnimating) {
      _objectMotionController.repeat();
    }
  }

  void _pauseObjectMotionAnimation() {
    if (_objectMotionController.isAnimating) {
      _objectMotionController.stop();
    }
  }

  void _handleTap() {
    if (_isRemoving) {
      return;
    }
    widget.onInteraction();
    widget.onBringToFront(widget.placed.instanceId);

    if (_bounceController.isAnimating) {
      return;
    }

    _pauseObjectMotionAnimation();
    _bounceController.forward(from: 0).whenComplete(() {
      if (mounted && !_isDragging) {
        _startObjectMotionAnimation();
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isRemoving) {
      return;
    }
    widget.onInteraction();
    widget.onBringToFront(widget.placed.instanceId);
    _dragStartPosition = _stageRuntime.position;
    _isDragging = true;
    setState(() {
      _stageRuntime = _stageMotionEngine.pauseForDrag(_stageRuntime);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isRemoving || !_isDragging) {
      return;
    }
    widget.onInteraction();

    final base = widget.stageSize;
    if (base.width <= 0 || base.height <= 0) {
      return;
    }

    final nextX = _dragStartPosition.dx + details.delta.dx / base.width;
    final nextY = _dragStartPosition.dy + details.delta.dy / base.height;
    final nextRuntime = _stageMotionEngine.applyDragPosition(
      runtime: _stageRuntime,
      draggedPosition: Offset(nextX, nextY),
      stageSize: widget.stageSize,
      objectSize: _characterDisplaySize(
        widget.placed,
        includePlacedScale: true,
      ),
    );
    final nextPosition = nextRuntime.position;
    _dragStartPosition = nextPosition;

    if (!_isSameRuntime(nextRuntime, _stageRuntime)) {
      setState(() {
        _stageRuntime = nextRuntime;
      });
    }
    widget.onMove(widget.placed.instanceId, nextPosition);
  }

  void _handlePanEnd(DragEndDetails _) {
    if (_isRemoving) {
      return;
    }
    _resumeStageMotionFromDrag();
  }

  void _handlePanCancel() {
    if (_isRemoving || !_isDragging) {
      return;
    }
    _resumeStageMotionFromDrag();
  }

  Future<void> _handleRemoveRequest() async {
    if (_isRemoving) {
      return;
    }
    await widget.onDelete(widget.placed.instanceId);
  }

  void _resumeStageMotionFromDrag() {
    final resumedRuntime = _stageMotionEngine.resumeFromDrag(
      runtime: _stageRuntime,
      droppedPosition: _stageRuntime.position,
      stageSize: widget.stageSize,
      objectSize: _characterDisplaySize(
        widget.placed,
        includePlacedScale: true,
      ),
    );

    _isDragging = false;
    if (!_isSameRuntime(resumedRuntime, _stageRuntime)) {
      setState(() {
        _stageRuntime = resumedRuntime;
      });
    } else {
      _stageRuntime = resumedRuntime;
    }

    widget.onMove(widget.placed.instanceId, resumedRuntime.position);
    _startObjectMotionAnimation();
  }

  bool _isSameRuntime(StageMotionRuntimeState a, StageMotionRuntimeState b) {
    return a.position == b.position &&
        a.direction == b.direction &&
        a.speed == b.speed &&
        a.isFlippedHorizontally == b.isFlippedHorizontally &&
        a.isPaused == b.isPaused;
  }

  Offset _objectMotionOffset() {
    final wave = math.sin(_objectMotionPhase.value * math.pi * 2);
    final stageHeight = widget.stageSize.height <= 0
        ? 1.0
        : widget.stageSize.height;
    final floatingOffsetY = 20 / stageHeight;
    final bouncingOffsetY = 40 / stageHeight;
    final glidingOffsetY = 12 / stageHeight;

    return switch (widget.placed.objectMotion) {
      MotionPreset.floating => Offset(0.0, wave * floatingOffsetY),
      MotionPreset.bouncing => Offset(0.0, -wave.abs() * bouncingOffsetY),
      MotionPreset.gliding => Offset(0.0, wave * glidingOffsetY),
      MotionPreset.rolling => Offset.zero,
    };
  }

  double _objectMotionRotation() {
    final cycle = _objectMotionPhase.value * math.pi * 2;
    return switch (widget.placed.objectMotion) {
      MotionPreset.gliding => math.sin(cycle) * 0.08,
      MotionPreset.rolling => cycle,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final x = _stageRuntime.position.dx;
    final y = _stageRuntime.position.dy.clamp(0.0, 1.0);
    final canInteract = !_isRemoving;
    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _entryScale,
          _bounceScale,
          _objectMotionController,
          _removeController,
        ]),
        builder: (context, child) {
          final objectMotionOffset = _objectMotionOffset();
          final objectMotionRotation = _objectMotionRotation();
          final removeOffsetY = _isRemoving ? _removeTranslateY.value : 0.0;
          final removeOffsetX = _isRemoving
              ? _removeTranslateXFactor.value * _removeTranslateXEnd
              : 0.0;
          final entryOpacity = _entryOpacity.value.clamp(0.0, 1.0);
          final opacity = _isRemoving
              ? _removeOpacity.value.clamp(0.0, 1.0)
              : entryOpacity;
          final removeScale = _isRemoving ? _removeScale.value : 1.0;
          final removeRotation = _isRemoving
              ? _removeRotateFactor.value * _removeRotationEnd
              : 0.0;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale:
                  _entryScale.value *
                  _bounceScale.value *
                  widget.placed.scale *
                  removeScale,
              child: Transform.translate(
                offset: Offset(
                  objectMotionOffset.dx * widget.stageSize.width +
                      removeOffsetX,
                  objectMotionOffset.dy * widget.stageSize.height +
                      removeOffsetY,
                ),
                child: Transform.rotate(
                  angle: objectMotionRotation + removeRotation,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: GestureDetector(
          onTap: canInteract ? _handleTap : null,
          onPanStart: canInteract ? _handlePanStart : null,
          onPanUpdate: canInteract ? _handlePanUpdate : null,
          onPanEnd: canInteract ? _handlePanEnd : null,
          onPanCancel: canInteract ? _handlePanCancel : null,
          onLongPress: canInteract
              ? () {
                  widget.onInteraction();
                  _handleRemoveRequest();
                }
              : null,
          child: _PlacedCharacterBubble(
            placed: widget.placed,
            onImageReady: _handleCharacterImageReady,
          ),
        ),
      ),
    );
  }
}

class _ConfettiEffectOverlay extends StatefulWidget {
  const _ConfettiEffectOverlay({
    required this.bursts,
    required this.onBurstsCompleted,
  });

  final List<_ConfettiBurstRequest> bursts;
  final ValueChanged<Set<int>> onBurstsCompleted;

  @override
  State<_ConfettiEffectOverlay> createState() => _ConfettiEffectOverlayState();
}

class _ConfettiEffectOverlayState extends State<_ConfettiEffectOverlay>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  final Map<int, _ConfettiBurstRuntime> _activeBursts =
      <int, _ConfettiBurstRuntime>{};
  late final Ticker _ticker;
  Duration _lastTickerElapsed = Duration.zero;
  double _clockSeconds = 0.0;
  bool _isTicking = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _syncBurstRequests();
  }

  @override
  void didUpdateWidget(covariant _ConfettiEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBurstRequests();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _syncBurstRequests() {
    var hasNewBurst = false;
    final nowSec = _clockSeconds;
    for (final request in widget.bursts) {
      if (_activeBursts.containsKey(request.id)) {
        continue;
      }
      _activeBursts[request.id] = _buildBurstRuntime(request, nowSec);
      hasNewBurst = true;
    }

    if (hasNewBurst) {
      if (!_isTicking) {
        _startTicker();
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _startTicker() {
    _lastTickerElapsed = Duration.zero;
    _isTicking = true;
    _ticker.start();
  }

  _ConfettiBurstRuntime _buildBurstRuntime(
    _ConfettiBurstRequest request,
    double nowSec,
  ) {
    final particles = List.generate(request.count, (_) {
      final size =
          _StageEffectConfig.confettiMinSize +
          _random.nextDouble() *
              (_StageEffectConfig.confettiMaxSize -
                  _StageEffectConfig.confettiMinSize);
      final lifetimeMs =
          _StageEffectConfig.confettiMinDurationMs +
          _random.nextInt(
            _StageEffectConfig.confettiMaxDurationMs -
                _StageEffectConfig.confettiMinDurationMs +
                1,
          );
      final lifetimeSec = lifetimeMs / 1000;
      final delaySec = _random.nextDouble() * 0.14;
      final isCircle = _random.nextDouble() < 0.12;
      final aspectRatio = 0.6 + (_random.nextDouble() * 1.2);
      final drift =
          (_random.nextDouble() - 0.5) * _StageEffectConfig.confettiDriftRange;
      final wobbleAmplitude = 3.5 + (_random.nextDouble() * 8.0);
      final wobbleFrequency = 1.2 + (_random.nextDouble() * 2.4);
      final rotationSpeed =
          (_random.nextDouble() * math.pi * 3.6) *
          (_random.nextBool() ? 1 : -1);

      return _ConfettiParticle(
        startXOffset:
            (_random.nextDouble() - 0.5) *
            (request.objectWidth * 1.1).clamp(
              42.0,
              _StageEffectConfig.confettiSpawnAreaWidth,
            ),
        startYOffset: -6.0 + (_random.nextDouble() * 12.0),
        endYOffset: _random.nextDouble() * 18.0,
        driftX: drift,
        wobbleAmplitude: wobbleAmplitude,
        wobbleFrequency: wobbleFrequency,
        wobblePhase: _random.nextDouble() * math.pi * 2,
        rotationStart: _random.nextDouble() * math.pi * 2,
        rotationSpeed: rotationSpeed,
        size: size,
        aspectRatio: aspectRatio,
        color:
            _StageEffectConfig.confettiColorPalette[_random.nextInt(
              _StageEffectConfig.confettiColorPalette.length,
            )],
        lifeSeconds: lifetimeSec,
        delaySeconds: delaySec,
        isCircle: isCircle,
      );
    });

    final maxParticleTime = particles
        .map((particle) => particle.delaySeconds + particle.lifeSeconds)
        .fold<double>(0.0, math.max);
    return _ConfettiBurstRuntime(
      id: request.id,
      normalizedX: request.normalizedX,
      normalizedY: request.normalizedY,
      objectHeight: request.objectHeight,
      startedAtSeconds: nowSec,
      endAtSeconds: nowSec + maxParticleTime + 0.04,
      particles: particles,
    );
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTickerElapsed;
    _lastTickerElapsed = elapsed;
    if (delta.isNegative) {
      return;
    }
    _clockSeconds += delta.inMicroseconds / Duration.microsecondsPerSecond;
    if (!mounted) {
      return;
    }

    final nowSec = _clockSeconds;
    final completedIds = _activeBursts.values
        .where((burst) => burst.endAtSeconds <= nowSec)
        .map((burst) => burst.id)
        .toSet();

    if (completedIds.isNotEmpty) {
      for (final id in completedIds) {
        _activeBursts.remove(id);
      }
      widget.onBurstsCompleted(completedIds);
    }

    if (_activeBursts.isEmpty) {
      _ticker.stop();
      _isTicking = false;
      setState(() {});
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_activeBursts.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ConfettiPainter(
            bursts: _activeBursts.values.toList(growable: false),
            elapsedSeconds: _clockSeconds,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.bursts, required this.elapsedSeconds});

  final List<_ConfettiBurstRuntime> bursts;
  final double elapsedSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    for (final burst in bursts) {
      final spawnX = burst.normalizedX * size.width;
      final centerY = burst.normalizedY * size.height;
      final objectTopY = centerY - (burst.objectHeight / 2);
      final objectBottomY = centerY + (burst.objectHeight / 2);
      for (final particle in burst.particles) {
        final localTime =
            elapsedSeconds - burst.startedAtSeconds - particle.delaySeconds;
        if (localTime < 0) {
          continue;
        }

        final progress = (localTime / particle.lifeSeconds).clamp(0.0, 1.0);
        if (progress >= 1.0) {
          continue;
        }

        final easedFall = Curves.easeIn.transform(progress);
        final startY =
            objectTopY - (burst.objectHeight * 0.5) + particle.startYOffset;
        final endY = objectBottomY + particle.endYOffset;
        final y = startY + ((endY - startY) * easedFall);

        final x =
            spawnX +
            particle.startXOffset +
            (particle.driftX * progress) +
            math.sin(
                  progress * math.pi * 2 * particle.wobbleFrequency +
                      particle.wobblePhase,
                ) *
                particle.wobbleAmplitude;

        var opacity = 1.0;
        if (progress < 0.12) {
          opacity *= Curves.easeOut.transform(progress / 0.12);
        }
        if (progress > 0.76) {
          opacity *= 1.0 - ((progress - 0.76) / 0.24).clamp(0.0, 1.0);
        }

        if (opacity <= 0.0) {
          continue;
        }

        final rotation =
            particle.rotationStart + (particle.rotationSpeed * progress);
        final paint = Paint()
          ..color = particle.color.withValues(alpha: opacity.clamp(0.0, 1.0));

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rotation);
        if (particle.isCircle) {
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
        } else {
          final width = particle.size * particle.aspectRatio;
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: width,
            height: particle.size,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(1.2)),
            paint,
          );
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.bursts != bursts ||
        oldDelegate.elapsedSeconds != elapsedSeconds;
  }
}

@immutable
class _ConfettiBurstRuntime {
  const _ConfettiBurstRuntime({
    required this.id,
    required this.normalizedX,
    required this.normalizedY,
    required this.objectHeight,
    required this.startedAtSeconds,
    required this.endAtSeconds,
    required this.particles,
  });

  final int id;
  final double normalizedX;
  final double normalizedY;
  final double objectHeight;
  final double startedAtSeconds;
  final double endAtSeconds;
  final List<_ConfettiParticle> particles;
}

@immutable
class _ConfettiParticle {
  const _ConfettiParticle({
    required this.startXOffset,
    required this.startYOffset,
    required this.endYOffset,
    required this.driftX,
    required this.wobbleAmplitude,
    required this.wobbleFrequency,
    required this.wobblePhase,
    required this.rotationStart,
    required this.rotationSpeed,
    required this.size,
    required this.aspectRatio,
    required this.color,
    required this.lifeSeconds,
    required this.delaySeconds,
    required this.isCircle,
  });

  final double startXOffset;
  final double startYOffset;
  final double endYOffset;
  final double driftX;
  final double wobbleAmplitude;
  final double wobbleFrequency;
  final double wobblePhase;
  final double rotationStart;
  final double rotationSpeed;
  final double size;
  final double aspectRatio;
  final Color color;
  final double lifeSeconds;
  final double delaySeconds;
  final bool isCircle;
}

class _PlacedCharacterBubble extends StatelessWidget {
  const _PlacedCharacterBubble({
    required this.placed,
    required this.onImageReady,
  });

  final PlacedCharacter placed;
  final VoidCallback onImageReady;

  @override
  Widget build(BuildContext context) {
    final displaySize = _characterDisplaySize(placed);
    return SizedBox(
      width: displaySize.width,
      height: displaySize.height,
      child: Image.file(
        File(placed.transparentImagePath),
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            onImageReady();
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          onImageReady();
          return const Center(child: Icon(Icons.image_not_supported));
        },
      ),
    );
  }
}

Size _characterDisplaySize(
  PlacedCharacter placed, {
  bool includePlacedScale = false,
}) {
  const maxDisplaySize = 120.0;
  final sourceWidth = placed.sourceWidth <= 0
      ? 1.0
      : placed.sourceWidth.toDouble();
  final sourceHeight = placed.sourceHeight <= 0
      ? 1.0
      : placed.sourceHeight.toDouble();
  final longestEdge = math.max(sourceWidth, sourceHeight);
  final scale = maxDisplaySize / longestEdge;
  final placedScale = includePlacedScale ? placed.scale : 1.0;

  return Size(
    sourceWidth * scale * placedScale,
    sourceHeight * scale * placedScale,
  );
}
