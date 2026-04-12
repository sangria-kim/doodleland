import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import 'library_viewmodel.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.onCharacterSelected});

  final ValueChanged<Character>? onCharacterSelected;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
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

    return Scaffold(
      appBar: AppBar(title: const Text('그림 라이브러리')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.errorMessage != null) ...[
                Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: const Text('라이브러리를 불러오지 못했습니다'),
                    subtitle: Text(state.errorMessage!),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: state.isLoading
                          ? null
                          : () => ref
                                .read(libraryViewModelProvider.notifier)
                                .loadCharacters(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: _LibraryContent(
                  state: state,
                  onRefresh: () => ref
                      .read(libraryViewModelProvider.notifier)
                      .loadCharacters(),
                  screen: this,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({
    required this.state,
    required this.onRefresh,
    required this.screen,
  });

  final LibraryState state;
  final Future<void> Function() onRefresh;
  final _LibraryScreenState screen;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.characters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '아직 그림이 없어요! 그림을 만들어볼까요?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.push('/capture'),
              child: const Text('그림 만들기'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: _CharacterGrid(
            characters: state.characters,
            deletingCharacterId: state.deletingCharacterId,
            onTapCharacter: _handleTap,
            onDeleteCharacter: _handleDelete,
          ),
        ),
        if (state.isLoading)
          const Positioned(
            right: 16,
            top: 16,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Future<void> _handleTap(Character character) async {
    if (screen.widget.onCharacterSelected != null) {
      screen.widget.onCharacterSelected!(character);
      return;
    }

    ScaffoldMessenger.of(
      screen.context,
    ).showSnackBar(const SnackBar(content: Text('현재는 목록 보기만 지원합니다.')));
  }

  Future<void> _handleDelete(Character character) async {
    final screenContext = screen.context;
    final scaffoldMessenger = ScaffoldMessenger.of(screenContext);

    final confirmed = await showDialog<bool>(
      context: screenContext,
      builder: (context) => AlertDialog(
        title: const Text('그림 삭제'),
        content: Text('${character.name}을(를) 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (!screen.mounted || confirmed != true) {
      return;
    }

    final isDeleted = await screen.ref
        .read(libraryViewModelProvider.notifier)
        .deleteCharacter(character);

    if (!screen.mounted) {
      return;
    }

    final message = isDeleted ? '삭제했습니다.' : '삭제에 실패했습니다.';
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CharacterGrid extends StatelessWidget {
  const _CharacterGrid({
    required this.characters,
    required this.deletingCharacterId,
    required this.onTapCharacter,
    required this.onDeleteCharacter,
  });

  final List<Character> characters;
  final int? deletingCharacterId;
  final Future<void> Function(Character character) onTapCharacter;
  final Future<void> Function(Character character) onDeleteCharacter;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: characters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final character = characters[index];
        return _CharacterCard(
          character: character,
          onTap: onTapCharacter,
          onLongPress: onDeleteCharacter,
          isDeleting: deletingCharacterId == character.id,
        );
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.onTap,
    required this.onLongPress,
    required this.isDeleting,
  });

  final Character character;
  final Future<void> Function(Character) onTap;
  final Future<void> Function(Character) onLongPress;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Card(
        child: InkWell(
          onTap: () => onTap(character),
          onLongPress: () => onLongPress(character),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CheckerboardTile(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: character.width.toDouble(),
                      height: character.height.toDouble(),
                      child: Image.file(
                        File(character.thumbnailPath),
                        fit: BoxFit.contain,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) =>
                            const Icon(Icons.image),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox.shrink(),
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
                    shadows: const [Shadow(color: Colors.white, blurRadius: 2)],
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
