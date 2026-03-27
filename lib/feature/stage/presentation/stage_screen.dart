import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/model/placed_character.dart';
import '../domain/model/motion_preset.dart';
import 'stage_viewmodel.dart';
import 'widget/character_selector.dart';

class StageScreen extends ConsumerWidget {
  const StageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    : _PlacedCharactersStage(placedCharacters: state.placedCharacters),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Tooltip(
        message: state.isFull ? '무대가 꽉 찼어요!' : '그림 추가',
        child: FloatingActionButton(
          onPressed: state.isFull ? null : () => _openCharacterSelector(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _openCharacterSelector(BuildContext context, WidgetRef ref) async {
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
  const _PlacedCharactersStage({required this.placedCharacters});

  final List<PlacedCharacter> placedCharacters;

  @override
  Widget build(BuildContext context) {
    final sortedCharacters = [...placedCharacters]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Stack(
      children: [
        for (final placed in sortedCharacters)
          _AppearingPlacedCharacter(placed: placed),
      ],
    );
  }
}

class _AppearingPlacedCharacter extends StatefulWidget {
  const _AppearingPlacedCharacter({required this.placed});

  final PlacedCharacter placed;

  @override
  State<_AppearingPlacedCharacter> createState() =>
      _AppearingPlacedCharacterState();
}

class _AppearingPlacedCharacterState extends State<_AppearingPlacedCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scale = TweenSequence<double>([
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
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final x = widget.placed.position.dx.clamp(0.0, 1.0);
    final y = widget.placed.position.dy.clamp(0.0, 1.0);
    return Align(
      alignment: Alignment(
        x * 2 - 1,
        y * 2 - 1,
      ),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value * widget.placed.scale,
          child: child,
        ),
        child: _PlacedCharacterBubble(placed: widget.placed),
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
