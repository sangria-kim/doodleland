import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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
                child: state.placedCharacters.isEmpty
                    ? _EmptyStageHint()
                    : _PlacedCharactersGrid(placedCharacters: state.placedCharacters),
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

class _PlacedCharactersGrid extends StatelessWidget {
  const _PlacedCharactersGrid({required this.placedCharacters});

  final List<PlacedCharacter> placedCharacters;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: placedCharacters.length,
      itemBuilder: (context, index) {
        final placed = placedCharacters[index];
        return Card(
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
        );
      },
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
