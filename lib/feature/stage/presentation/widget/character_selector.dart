import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/presentation/character_thumbnail_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../stage/domain/model/motion_preset.dart';
import '../../../library/presentation/library_viewmodel.dart';
import 'motion_selector.dart';

class CharacterPlacementSelection {
  const CharacterPlacementSelection({
    required this.character,
    required this.objectMotion,
  });

  final Character character;
  final MotionPreset objectMotion;
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
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = math.min(
      mediaQuery.size.height * 0.92,
      mediaQuery.size.height -
          mediaQuery.padding.bottom -
          mediaQuery.padding.top,
    );
    final isSelectingCharacter = _selectedCharacter == null;

    if (state.isLoading && state.characters.isEmpty) {
      return SizedBox(
        height: sheetHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetHeader(
                      title: isSelectingCharacter ? '그림을 골라봐!' : '움직임을 골라봐!',
                      subtitle: isSelectingCharacter
                          ? null
                          : '미리보기와 설명을 보고 원하는 움직임을 고른 뒤 무대에 등장시켜요.',
                    ),
                    SizedBox(height: isSelectingCharacter ? 12 : 20),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: state.characters.isEmpty
                            ? _EmptyCharacterState(
                                key: const ValueKey('empty-state'),
                                errorMessage: state.errorMessage,
                              )
                            : isSelectingCharacter
                            ? _CharacterSelectionList(
                                key: const ValueKey('character-list'),
                                state: state,
                                onTap: (character) {
                                  ref
                                      .read(
                                        characterSelectorSheetControllerProvider
                                            .notifier,
                                      )
                                      .selectMotion(MotionPreset.floating);
                                  setState(() {
                                    _selectedCharacter = character;
                                  });
                                },
                              )
                            : _MotionSelectionSheet(
                                key: ValueKey(_selectedCharacter!.id),
                                character: _selectedCharacter!,
                                onBack: () {
                                  setState(() {
                                    _selectedCharacter = null;
                                  });
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterSelectionList extends StatelessWidget {
  const _CharacterSelectionList({
    super.key,
    required this.state,
    required this.onTap,
  });

  final LibraryState state;
  final ValueChanged<Character> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: state.characters.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
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
        ),
      ),
    );
  }
}

class _MotionSelectionSheet extends StatelessWidget {
  const _MotionSelectionSheet({
    super.key,
    required this.character,
    required this.onBack,
  });

  final Character character;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(characterSelectorSheetControllerProvider);
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _CharacterPreviewPanel(
                                  character: character,
                                  selectedMotion: state,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 5,
                                child: _MotionSelectionPanel(
                                  selectedMotion: state,
                                  onChanged: (motion) {
                                    ref
                                        .read(
                                          characterSelectorSheetControllerProvider
                                              .notifier,
                                        )
                                        .selectMotion(motion);
                                  },
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CharacterPreviewPanel(
                                character: character,
                                selectedMotion: state,
                              ),
                              const SizedBox(height: 16),
                              _MotionSelectionPanel(
                                selectedMotion: state,
                                onChanged: (motion) {
                                  ref
                                      .read(
                                        characterSelectorSheetControllerProvider
                                            .notifier,
                                      )
                                      .selectMotion(motion);
                                },
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                _SheetActionBar(
                  onBack: onBack,
                  onConfirm: () {
                    Navigator.of(context).pop(
                      CharacterPlacementSelection(
                        character: character,
                        objectMotion: state,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CharacterSelectorSheetState extends StateNotifier<MotionPreset> {
  CharacterSelectorSheetState() : super(MotionPreset.floating);

  void selectMotion(MotionPreset motion) {
    state = motion;
  }
}

final characterSelectorSheetControllerProvider =
    StateNotifierProvider<CharacterSelectorSheetState, MotionPreset>(
      (ref) => CharacterSelectorSheetState(),
    );

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.15,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyCharacterState extends StatelessWidget {
  const _EmptyCharacterState({super.key, required this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.collections_outlined,
                  size: 44,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '아직 그림이 없어요',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '그림을 먼저 만든 뒤 무대에 올려볼까요?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/capture');
                    },
                    child: const Text('그림 만들기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterPreviewPanel extends StatelessWidget {
  const _CharacterPreviewPanel({
    required this.character,
    required this.selectedMotion,
  });

  final Character character;
  final MotionPreset selectedMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: 128,
                height: 128,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: _CheckerboardTile(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: character.width.toDouble(),
                          height: character.height.toDouble(),
                          child: Image.file(
                            File(character.thumbnailPath),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              character.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '현재 선택한 움직임',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedMotion.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedMotion.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotionSelectionPanel extends StatelessWidget {
  const _MotionSelectionPanel({
    required this.selectedMotion,
    required this.onChanged,
  });

  final MotionPreset selectedMotion;
  final ValueChanged<MotionPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '움직임을 선택해줘',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '움직임 설명을 읽고 카드 하나를 선택하면 바로 미리보기에 반영돼요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            MotionSelector(
              selectedMotion: selectedMotion,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionBar extends StatelessWidget {
  const _SheetActionBar({required this.onBack, required this.onConfirm});

  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final actionTextStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
    );

    Widget buildButton({
      required Widget child,
      required VoidCallback onPressed,
      required bool primary,
    }) {
      final button = primary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                textStyle: actionTextStyle,
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                foregroundColor: AppPalette.primaryDark,
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                textStyle: actionTextStyle,
              ),
              child: child,
            );

      return SizedBox(height: 72, child: button);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: buildButton(
                  onPressed: onBack,
                  primary: false,
                  child: const Text('그림 다시 고르기'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: buildButton(
                  onPressed: onConfirm,
                  primary: true,
                  child: const Text('등장하기'),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: buildButton(
                onPressed: onBack,
                primary: false,
                child: const Text('그림 다시 고르기'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildButton(
                onPressed: onConfirm,
                primary: true,
                child: const Text('등장하기'),
              ),
            ),
          ],
        );
      },
    );
  }
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
    return CharacterThumbnailCard(
      character: character,
      isDeleting: isDeleting,
      onTap: () => onTap(character),
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
