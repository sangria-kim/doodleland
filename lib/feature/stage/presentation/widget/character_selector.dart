import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../stage/domain/model/motion_preset.dart';
import '../../../library/presentation/library_viewmodel.dart';
import 'motion_selector.dart';

class CharacterPlacementSelection {
  const CharacterPlacementSelection({
    required this.character,
    required this.motion,
  });

  final Character character;
  final MotionPreset motion;
}

class CharacterSelector extends ConsumerStatefulWidget {
  const CharacterSelector({super.key});

  @override
  ConsumerState<CharacterSelector> createState() => _CharacterSelectorState();
}

class _CharacterSelectorState extends ConsumerState<CharacterSelector> {
  Character? _selectedCharacter;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(libraryViewModelProvider.notifier).loadCharacters(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryViewModelProvider);

    if (state.isLoading && state.characters.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '그림을 골라봐!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (state.characters.isEmpty) ...[
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '아직 그림이 없어요! 그림을 먼저 만들어볼까요?',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/capture');
                          },
                          child: const Text('그림 만들기'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                if (_selectedCharacter == null)
                  Expanded(
                    child: _CharacterSelectionList(
                      state: state,
                      onTap: (character) {
                        ref
                            .read(characterSelectorSheetControllerProvider.notifier)
                            .selectMotion(MotionPreset.floating);
                        setState(() {
                          _selectedCharacter = character;
                        });
                      },
                    ),
                  )
                else
                  Expanded(child: _MotionSelectionSheet(character: _selectedCharacter!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterSelectionList extends StatelessWidget {
  const _CharacterSelectionList({
    required this.state,
    required this.onTap,
  });

  final LibraryState state;
  final ValueChanged<Character> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: state.characters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final character = state.characters[index];
        final isDeleting = state.deletingCharacterId == character.id;
        return _CharacterCard(
          character: character,
          isDeleting: isDeleting,
          onTap: onTap,
        );
      },
    );
  }
}

class _MotionSelectionSheet extends StatelessWidget {
  const _MotionSelectionSheet({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(characterSelectorSheetControllerProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: 88,
                height: 88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Image.file(
                    File(character.thumbnailPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '움직임을 선택한 뒤 등장하기를 눌러요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            MotionSelector(
              selectedMotion: state.motion,
              onChanged: (motion) {
                ref.read(characterSelectorSheetControllerProvider.notifier).selectMotion(
                  motion,
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('뒤로가기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        CharacterPlacementSelection(
                          character: character,
                          motion: state.motion,
                        ),
                      );
                    },
                    child: const Text('등장하기'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class CharacterSelectorSheetState extends StateNotifier<MotionPreset> {
  CharacterSelectorSheetState() : super(MotionPreset.floating);

  MotionPreset get motion => state;

  void selectMotion(MotionPreset motion) {
    state = motion;
  }
}

final characterSelectorSheetControllerProvider =
    StateNotifierProvider<CharacterSelectorSheetState, MotionPreset>(
      (ref) => CharacterSelectorSheetState(),
    );
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.onTap,
    required this.isDeleting,
  });

  final Character character;
  final ValueChanged<Character> onTap;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Card(
        child: InkWell(
          onTap: isDeleting ? null : () => onTap(character),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CheckerboardTile(
                child: Image.file(
                  File(character.thumbnailPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, _, __) => const Icon(Icons.image),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 4,
                child: Text(
                  character.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.black87,
                        shadows: const [
                          Shadow(
                            color: Colors.white,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                ),
              ),
              if (isDeleting)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckerboardTile extends StatelessWidget {
  const _CheckerboardTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(),
      child: CustomPaint(
        painter: const _CheckerboardPainter(),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const light = Color(0xFFF3F3F3);
    const dark = Color(0xFFE4E4E4);
    const tile = 12.0;

    final lightPaint = Paint()..color = light;
    final darkPaint = Paint()..color = dark;

    canvas.drawRect(Offset.zero & size, lightPaint);

    for (var row = 0; row * tile < size.height; row += 1) {
      for (var col = 0; col * tile < size.width; col += 1) {
        if ((row + col).isOdd) {
          canvas.drawRect(
            Rect.fromLTWH(col * tile, row * tile, tile, tile),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
