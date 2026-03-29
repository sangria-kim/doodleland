import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/model/placed_character.dart';
import '../domain/model/motion_preset.dart';
import 'stage_viewmodel.dart';
import 'widget/character_selector.dart';

class StageScreen extends ConsumerStatefulWidget {
  const StageScreen({super.key});

  @override
  ConsumerState<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends ConsumerState<StageScreen> {
  static const Duration _controlHideDelay = Duration(seconds: 2);

  bool _showControls = true;
  Timer? _controlTimer;

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stageViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.of(context).padding.top;
          final horizontalPadding = 16.0;
          final overlayColor = Colors.black.withOpacity(0.36);
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
                            final removed = ref
                                .read(stageViewModelProvider.notifier)
                                .removeCharacter(instanceId);

                            if (context.mounted) {
                              final message = removed
                                  ? '무대에서 제거했어요.'
                                  : '제거하지 못했어요.';
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(message)));
                            }
                          },
                        ),
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
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                        shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
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
                    color: Colors.red.shade50.withOpacity(0.9),
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
    final selection = await showModalBottomSheet<CharacterPlacementSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const CharacterSelector(),
    );

    if (!context.mounted || selection == null) {
      return;
    }

    final isAdded = await ref
        .read(stageViewModelProvider.notifier)
        .placeCharacter(
          character: selection.character,
          motionPreset: selection.motion,
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
  });

  final List<PlacedCharacter> placedCharacters;
  final Size stageSize;
  final VoidCallback onInteraction;
  final ValueChanged<String> onBringToFront;
  final void Function(String instanceId, Offset position) onMove;
  final Future<void> Function(String instanceId) onDelete;

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
  });

  final PlacedCharacter placed;
  final Size stageSize;
  final VoidCallback onInteraction;
  final ValueChanged<String> onBringToFront;
  final void Function(String instanceId, Offset position) onMove;
  final Future<void> Function(String instanceId) onDelete;

  @override
  State<_InteractivePlacedCharacter> createState() =>
      _InteractivePlacedCharacterState();
}

class _InteractivePlacedCharacterState
    extends State<_InteractivePlacedCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _entryScale;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;
  late final AnimationController _motionController;
  late final Animation<double> _motionPhase;

  Offset _dragStartPosition = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _entryScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_entryController);

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
    _motionController = AnimationController(
      vsync: this,
      duration: _motionDuration(),
    );
    _motionPhase = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _motionController, curve: Curves.linear));

    _entryController.forward();
    _startMotionAnimation();

    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isDragging && mounted) {
        _startMotionAnimation();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _bounceController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  Duration _motionDuration() {
    return switch (widget.placed.motionPreset) {
      MotionPreset.floating => const Duration(milliseconds: 2000),
      MotionPreset.bouncing => const Duration(milliseconds: 1200),
      MotionPreset.gliding => const Duration(milliseconds: 3000),
      MotionPreset.rolling => const Duration(milliseconds: 2500),
      MotionPreset.spinning => const Duration(milliseconds: 1500),
    };
  }

  void _startMotionAnimation() {
    if (_isDragging) {
      return;
    }
    if (!_motionController.isAnimating) {
      _motionController.repeat();
    }
  }

  void _pauseMotionAnimation() {
    if (_motionController.isAnimating) {
      _motionController.stop();
    }
  }

  void _handleTap() {
    widget.onInteraction();
    widget.onBringToFront(widget.placed.instanceId);

    if (_bounceController.isAnimating) {
      return;
    }

    _pauseMotionAnimation();
    _bounceController.forward(from: 0).whenComplete(() {
      if (mounted && !_isDragging) {
        _startMotionAnimation();
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    widget.onInteraction();
    widget.onBringToFront(widget.placed.instanceId);
    _dragStartPosition = widget.placed.position;
    _isDragging = true;
    _pauseMotionAnimation();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) {
      return;
    }
    widget.onInteraction();

    final base = widget.stageSize;
    if (base.width <= 0 || base.height <= 0) {
      return;
    }

    final nextX = _dragStartPosition.dx + details.delta.dx / base.width;
    final nextY = _dragStartPosition.dy + details.delta.dy / base.height;
    final nextPosition = _clampPosition(Offset(nextX, nextY));
    _dragStartPosition = nextPosition;

    widget.onMove(widget.placed.instanceId, nextPosition);
  }

  void _handlePanEnd(DragEndDetails _) {
    _isDragging = false;
    _startMotionAnimation();
  }

  Offset _clampPosition(Offset position) {
    return Offset(position.dx.clamp(0.0, 1.0), position.dy.clamp(0.0, 1.0));
  }

  Offset _motionOffset() {
    final wave = math.sin(_motionPhase.value * math.pi * 2);
    final stageHeight = widget.stageSize.height <= 0
        ? 1.0
        : widget.stageSize.height;
    final stageWidth = widget.stageSize.width <= 0
        ? 1.0
        : widget.stageSize.width;
    final floatingOffsetY = 20 / stageHeight;
    final bouncingOffsetY = 40 / stageHeight;
    final glidingOffsetX = 60 / stageWidth;
    final rollingOffsetX = 80 / stageWidth;

    return switch (widget.placed.motionPreset) {
      MotionPreset.floating => Offset(0.0, wave * floatingOffsetY),
      MotionPreset.bouncing => Offset(0.0, -wave.abs() * bouncingOffsetY),
      MotionPreset.gliding => Offset(wave * glidingOffsetX, 0.0),
      MotionPreset.rolling => Offset(wave * rollingOffsetX, 0.0),
      MotionPreset.spinning => Offset.zero,
    };
  }

  double _motionRotation() {
    final wave = _motionPhase.value * math.pi * 2;
    return switch (widget.placed.motionPreset) {
      MotionPreset.rolling => wave,
      MotionPreset.spinning => wave,
      _ => 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final x = widget.placed.position.dx.clamp(0.0, 1.0);
    final y = widget.placed.position.dy.clamp(0.0, 1.0);
    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _entryScale,
          _bounceScale,
          _motionController,
        ]),
        builder: (context, child) {
          final motionOffset = _motionOffset();
          final motionRotation = _motionRotation();
          return Transform.scale(
            scale: _entryScale.value * _bounceScale.value * widget.placed.scale,
            child: Transform.translate(
              offset: Offset(
                motionOffset.dx * widget.stageSize.width,
                motionOffset.dy * widget.stageSize.height,
              ),
              child: Transform.rotate(angle: motionRotation, child: child),
            ),
          );
        },
        child: GestureDetector(
          onTap: _handleTap,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          onLongPress: () {
            widget.onInteraction();
            widget.onDelete(widget.placed.instanceId);
          },
          child: _PlacedCharacterBubble(placed: widget.placed),
        ),
      ),
    );
  }
}

class _PlacedCharacterBubble extends StatelessWidget {
  const _PlacedCharacterBubble({required this.placed});

  static const double _maxDisplaySize = 120;

  final PlacedCharacter placed;

  Size _displaySize() {
    final sourceWidth = placed.sourceWidth <= 0
        ? 1.0
        : placed.sourceWidth.toDouble();
    final sourceHeight = placed.sourceHeight <= 0
        ? 1.0
        : placed.sourceHeight.toDouble();
    final longestEdge = math.max(sourceWidth, sourceHeight);
    final scale = _maxDisplaySize / longestEdge;

    return Size(sourceWidth * scale, sourceHeight * scale);
  }

  @override
  Widget build(BuildContext context) {
    final displaySize = _displaySize();
    return SizedBox(
      width: displaySize.width,
      height: displaySize.height,
      child: Image.file(
        File(placed.transparentImagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.image_not_supported)),
      ),
    );
  }
}
