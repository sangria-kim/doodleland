import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../library/presentation/library_viewmodel.dart';
import '../domain/model/motion_preset.dart';
import 'widget/character_selector.dart';
import 'widget/motion_selector.dart';

enum _PlacementStep { character, motion }

class CharacterPlacementFlowScreen extends ConsumerStatefulWidget {
  const CharacterPlacementFlowScreen({super.key});

  @override
  ConsumerState<CharacterPlacementFlowScreen> createState() =>
      _CharacterPlacementFlowScreenState();
}

class _CharacterPlacementFlowScreenState
    extends ConsumerState<CharacterPlacementFlowScreen> {
  _PlacementStep _step = _PlacementStep.character;
  Character? _selectedCharacter;
  MotionPreset _selectedMotion = MotionPreset.floating;

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
    final isCharacterStep = _step == _PlacementStep.character;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCharacterStep ? '그림 고르기' : '움직임 고르기'),
        leading: IconButton(
          onPressed: () {
            if (!isCharacterStep) {
              setState(() {
                _step = _PlacementStep.character;
              });
              return;
            }
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로 가기',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: isCharacterStep
                        ? _CharacterStep(
                            key: const ValueKey('character-step'),
                            state: state,
                            selectedCharacter: _selectedCharacter,
                            onSelect: (character) {
                              setState(() {
                                _selectedCharacter = character;
                                _selectedMotion = MotionPreset.floating;
                              });
                            },
                            onCreateCharacter: () => context.push('/capture'),
                          )
                        : _MotionStep(
                            key: const ValueKey('motion-step'),
                            character: _selectedCharacter!,
                            selectedMotion: _selectedMotion,
                            onMotionChanged: (motion) {
                              setState(() {
                                _selectedMotion = motion;
                              });
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isCharacterStep)
                  _CharacterStepActionBar(
                    hasSelection: _selectedCharacter != null,
                    onNext: _selectedCharacter == null
                        ? null
                        : () {
                            setState(() {
                              _step = _PlacementStep.motion;
                            });
                          },
                  )
                else
                  _MotionStepActionBar(
                    onBack: () {
                      setState(() {
                        _step = _PlacementStep.character;
                      });
                    },
                    onConfirm: () {
                      final selectedCharacter = _selectedCharacter;
                      if (selectedCharacter == null) {
                        return;
                      }
                      context.pop(
                        CharacterPlacementSelection(
                          character: selectedCharacter,
                          objectMotion: _selectedMotion,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterStep extends StatelessWidget {
  const _CharacterStep({
    super.key,
    required this.state,
    required this.selectedCharacter,
    required this.onSelect,
    required this.onCreateCharacter,
  });

  final LibraryState state;
  final Character? selectedCharacter;
  final ValueChanged<Character> onSelect;
  final VoidCallback onCreateCharacter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading && state.characters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.characters.isEmpty) {
      return _EmptyCharacterList(onCreateCharacter: onCreateCharacter);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = switch (constraints.maxWidth) {
              >= 960 => 4,
              _ => 3,
            };

            return GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: state.characters.length,
              itemBuilder: (context, index) {
                final character = state.characters[index];
                return _CharacterGridCard(
                  character: character,
                  selected: selectedCharacter?.id == character.id,
                  onTap: () => onSelect(character),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyCharacterList extends StatelessWidget {
  const _EmptyCharacterList({required this.onCreateCharacter});

  final VoidCallback onCreateCharacter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.collections_outlined,
                  color: colorScheme.primary,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  '아직 그림이 없어요',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '그림을 먼저 만든 뒤 무대에 올려볼까요?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onCreateCharacter,
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

class _CharacterGridCard extends StatelessWidget {
  const _CharacterGridCard({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  final Character character;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  character.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _MotionStep extends StatelessWidget {
  const _MotionStep({
    super.key,
    required this.character,
    required this.selectedMotion,
    required this.onMotionChanged,
  });

  final Character character;
  final MotionPreset selectedMotion;
  final ValueChanged<MotionPreset> onMotionChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _CharacterPreviewCard(
            character: character,
            selectedMotion: selectedMotion,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: _MotionSelectionCard(
            selectedMotion: selectedMotion,
            onMotionChanged: onMotionChanged,
          ),
        ),
      ],
    );
  }
}

class _CharacterPreviewCard extends StatelessWidget {
  const _CharacterPreviewCard({
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
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewSize = (constraints.maxWidth * 0.62).clamp(
              112.0,
              240.0,
            );

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: previewSize,
                        height: previewSize,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _AnimatedCharacterPreview(
                            character: character,
                            motion: selectedMotion,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  character.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedCharacterPreview extends StatefulWidget {
  const _AnimatedCharacterPreview({
    required this.character,
    required this.motion,
  });

  final Character character;
  final MotionPreset motion;

  @override
  State<_AnimatedCharacterPreview> createState() =>
      _AnimatedCharacterPreviewState();
}

class _AnimatedCharacterPreviewState extends State<_AnimatedCharacterPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.motion),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCharacterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion) {
      _controller
        ..duration = _durationFor(widget.motion)
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _durationFor(MotionPreset motion) {
    return switch (motion) {
      MotionPreset.floating => const Duration(milliseconds: 2000),
      MotionPreset.bouncing => const Duration(milliseconds: 1200),
      MotionPreset.gliding => Duration(
        milliseconds: 2500 + (widget.character.id % 400),
      ),
      MotionPreset.fluttering => const Duration(milliseconds: 2800),
      MotionPreset.rolling => const Duration(milliseconds: 2500),
    };
  }

  double _initialMotionOffset() {
    final seed = (widget.character.id * 97) + widget.motion.index;
    return (seed.abs() % 1000) / 1000.0;
  }

  double _previewCycle() {
    return (_controller.value + _initialMotionOffset()) % 1.0;
  }

  double _glideProfile(double phase) {
    final primaryWave = math.sin(phase);
    final flutterWave = math.sin(phase * 2.4 + 0.35) * 0.26;
    final diveWeight = primaryWave < 0
        ? math.pow(-primaryWave, 1.35).toDouble() * 0.95
        : 0.0;

    return (primaryWave * 0.55 + flutterWave - diveWeight)
        .clamp(-1.6, 1.05)
        .toDouble();
  }

  double _glideRotation(double phase) {
    final profile = _glideProfile(phase);
    final nextProfile = _glideProfile(phase + 0.05);
    final profileVelocity = nextProfile - profile;
    final diveBias = profile < 0 ? 1.25 : 0.75;

    return (math.cos(phase) * 0.12 +
            profileVelocity * 2.6 +
            profile * 0.06 * diveBias)
        .clamp(-0.2, 0.2)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = math.min(constraints.maxWidth, constraints.maxHeight);
        final floatingOffsetY = boxSize * 0.09;
        final bouncingOffsetY = boxSize * 0.16;
        final glidingOffsetY = boxSize * 0.09;
        final flutteringDropY = boxSize * 0.62;
        final flutteringOffsetX = boxSize * 0.06;

        return AnimatedBuilder(
          animation: _controller,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: widget.character.width.toDouble(),
              height: widget.character.height.toDouble(),
              child: Image.file(
                File(widget.character.thumbnailPath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image),
              ),
            ),
          ),
      builder: (context, child) {
        final phase = _previewCycle() * math.pi * 2;
        final flutterWaveSecondary = math.sin(phase * 2);
        final flutterWaveTertiary = math.sin(phase * 3);
        final verticalOffset = switch (widget.motion) {
              MotionPreset.floating => math.sin(phase) * floatingOffsetY,
              MotionPreset.bouncing => -math.sin(phase).abs() * bouncingOffsetY,
              MotionPreset.gliding => _glideProfile(phase) * glidingOffsetY,
              MotionPreset.fluttering =>
                flutteringDropY * (1 - math.cos(phase)) * 0.5 +
                    flutterWaveSecondary * (boxSize * 0.02),
              MotionPreset.rolling => 0.0,
            };
            final horizontalOffset = switch (widget.motion) {
              MotionPreset.fluttering =>
                math.sin(phase + _initialMotionOffset() * 0.9) *
                        flutteringOffsetX +
                    flutterWaveSecondary * (flutteringOffsetX * 0.36),
              _ => 0.0,
            };
            final rotation = switch (widget.motion) {
              MotionPreset.gliding => _glideRotation(phase),
              MotionPreset.fluttering =>
                math.sin(phase + _initialMotionOffset() * 0.4) * 0.09 +
                    flutterWaveTertiary * 0.025,
              MotionPreset.rolling => phase,
              _ => 0.0,
            };

            return Transform.translate(
              offset: Offset(horizontalOffset, verticalOffset),
              child: Transform.rotate(angle: rotation, child: child),
            );
          },
        );
      },
    );
  }
}

class _MotionSelectionCard extends StatelessWidget {
  const _MotionSelectionCard({
    required this.selectedMotion,
    required this.onMotionChanged,
  });

  final MotionPreset selectedMotion;
  final ValueChanged<MotionPreset> onMotionChanged;

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
        padding: const EdgeInsets.all(16),
        child: MotionSelector(
          selectedMotion: selectedMotion,
          onChanged: onMotionChanged,
          compact: true,
        ),
      ),
    );
  }
}

class _CharacterStepActionBar extends StatelessWidget {
  const _CharacterStepActionBar({
    required this.hasSelection,
    required this.onNext,
  });

  final bool hasSelection;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(hasSelection ? '다음: 움직임 고르기' : '그림을 선택해줘'),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(hasSelection ? '다음: 움직임 고르기' : '그림을 선택해줘'),
          ),
        );
      },
    );
  }
}

class _MotionStepActionBar extends StatelessWidget {
  const _MotionStepActionBar({required this.onBack, required this.onConfirm});

  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('그림 다시 고르기'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('등장하기'),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('그림 다시 고르기'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('등장하기'),
              ),
            ),
          ],
        );
      },
    );
  }
}
