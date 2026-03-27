import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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
    _controlTimer = Timer(
      _controlHideDelay,
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          _showControls = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stageViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('무대'),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/stage/background'),
            icon: const Icon(Icons.image),
            tooltip: '배경 바꾸기',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '무대에 배치된 캐릭터: ${state.placedCharacters.length} / 10',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (state.errorMessage != null)
                Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(state.errorMessage!),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: ref.read(stageViewModelProvider.notifier).clearError,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _showControlsForAWhile,
                      onPanDown: (_) => _showControlsForAWhile(),
                      child: Container(
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: IgnorePointer(
        ignoring: !_showControls,
        child: AnimatedOpacity(
          opacity: _showControls ? 1 : 0,
          duration: const Duration(milliseconds: 420),
          child: Tooltip(
            message: state.isFull ? '무대가 꽉 찼어요!' : '그림 추가',
            child: FloatingActionButton(
              onPressed:
                  state.isFull ? null : () {
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

    final isAdded = await ref.read(stageViewModelProvider.notifier).placeCharacter(
          character: selection.character,
          motionPreset: selection.motion,
        );

    if (!context.mounted) {
      return;
    }

    final message = isAdded ? '무대에 등장했어요.' : '무대에 추가하지 못했어요.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        for (final placed in [...placedCharacters]..sort((a, b) => a.zIndex.compareTo(b.zIndex)))
          _InteractivePlacedCharacter(
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

class _InteractivePlacedCharacterState extends State<_InteractivePlacedCharacter>
    with TickerProviderStateMixin {
  static const double _cardSize = 120;

  late final AnimationController _entryController;
  late final Animation<double> _entryScale;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;

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
        tween: Tween(begin: 0.0, end: 1.2).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 55,
      ),
    ]).animate(_entryController);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.12).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 50,
      ),
    ]).animate(_bounceController);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onInteraction();
    widget.onBringToFront(widget.placed.instanceId);

    if (_bounceController.isAnimating) {
      return;
    }
    _bounceController.forward(from: 0);
  }

  void _handlePanStart(DragStartDetails details) {
    widget.onInteraction();
    widget.onBringToFront(widget.placed.instanceId);
    _dragStartPosition = widget.placed.position;
    _isDragging = true;
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
  }

  Offset _clampPosition(Offset position) {
    final halfNormalizedX = widget.stageSize.width <= _cardSize
        ? 0.5
        : _cardSize / widget.stageSize.width / 2;
    final halfNormalizedY = widget.stageSize.height <= _cardSize
        ? 0.5
        : _cardSize / widget.stageSize.height / 2;
    final safeLeft = halfNormalizedX.clamp(0.0, 0.5);
    final safeRight = (1.0 - halfNormalizedX).clamp(0.5, 1.0);
    final safeTop = halfNormalizedY.clamp(0.0, 0.5);
    final safeBottom = (1.0 - halfNormalizedY).clamp(0.5, 1.0);

    return Offset(
      position.dx.clamp(safeLeft, safeRight),
      position.dy.clamp(safeTop, safeBottom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final x = widget.placed.position.dx.clamp(0.0, 1.0);
    final y = widget.placed.position.dy.clamp(0.0, 1.0);
    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: AnimatedBuilder(
        animation: Listenable.merge([_entryScale, _bounceScale]),
        builder: (context, child) => Transform.scale(
          scale: _entryScale.value * _bounceScale.value * widget.placed.scale,
          child: child,
        ),
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

  final PlacedCharacter placed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(placed.transparentImagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => const Center(
                child: Icon(Icons.image_not_supported),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: _PlacedCharacterInfo(placed: placed),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacedCharacterInfo extends StatelessWidget {
  const _PlacedCharacterInfo({required this.placed});

  final PlacedCharacter placed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(
        '${placed.characterName} / ${placed.motionPreset.label}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
