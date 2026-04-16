import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/presentation/app_back_button.dart';
import '../../../core/presentation/character_thumbnail_card.dart';
import '../../../core/theme/app_theme.dart';
import 'library_viewmodel.dart';

enum LibraryCardAction { delete }

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
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.pageVertical +
                    (canPop ? AppBackButtonOverlay.contentTopClearance : 0),
                AppSpacing.pageHorizontal,
                AppSpacing.pageVertical,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.errorMessage != null) ...[
                    _LibraryErrorCard(
                      errorMessage: state.errorMessage!,
                      isRefreshing: state.isLoading,
                      onRetry: () => ref
                          .read(libraryViewModelProvider.notifier)
                          .loadCharacters(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: _LibraryContent(
                      state: state,
                      onRefresh: () => ref
                          .read(libraryViewModelProvider.notifier)
                          .loadCharacters(),
                      onTapCharacter: _handleTapCharacter,
                      onSelectedAction: _handleSelectedAction,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (canPop) const AppBackButtonOverlay(),
        ],
      ),
    );
  }

  Future<void> _handleTapCharacter(Character character) async {
    if (widget.onCharacterSelected != null) {
      widget.onCharacterSelected!(character);
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('준비 중인 기능이에요')));
  }

  Future<void> _handleSelectedAction(
    Character character,
    LibraryCardAction action,
  ) async {
    switch (action) {
      case LibraryCardAction.delete:
        await _confirmDelete(character);
    }
  }

  Future<void> _confirmDelete(Character character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 그림을 삭제할까요?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('삭제한 그림은 되돌릴 수 없어요.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final isDeleted = await ref
        .read(libraryViewModelProvider.notifier)
        .deleteCharacter(character);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(isDeleted ? '그림이 삭제되었어요' : '그림을 삭제하지 못했어요')),
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({
    required this.state,
    required this.onRefresh,
    required this.onTapCharacter,
    required this.onSelectedAction,
  });

  final LibraryState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Character character) onTapCharacter;
  final Future<void> Function(Character character, LibraryCardAction action)
  onSelectedAction;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.characters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.characters.isEmpty) {
      return const LibraryEmptyState();
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: _LibraryGrid(
            characters: state.characters,
            deletingCharacterId: state.deletingCharacterId,
            onTapCharacter: onTapCharacter,
            onSelectedAction: onSelectedAction,
          ),
        ),
        if (state.isLoading)
          const Positioned(
            top: 12,
            right: 12,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
      ],
    );
  }
}

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 52,
                  color: AppPalette.primaryDark.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 18),
                Text(
                  '아직 저장한 그림이 없어요',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '그림을 만들어서 나만의 그림책을 채워보세요',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppPalette.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => context.push('/capture'),
                  icon: const Icon(Icons.edit),
                  label: const Text('그림 만들기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryErrorCard extends StatelessWidget {
  const _LibraryErrorCard({
    required this.errorMessage,
    required this.isRefreshing,
    required this.onRetry,
  });

  final String errorMessage;
  final bool isRefreshing;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF2F0),
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text('내 그림을 불러오지 못했어요'),
        subtitle: Text(errorMessage),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: isRefreshing ? null : onRetry,
        ),
      ),
    );
  }
}

class _LibraryGrid extends StatelessWidget {
  const _LibraryGrid({
    required this.characters,
    required this.deletingCharacterId,
    required this.onTapCharacter,
    required this.onSelectedAction,
  });

  final List<Character> characters;
  final int? deletingCharacterId;
  final Future<void> Function(Character character) onTapCharacter;
  final Future<void> Function(Character character, LibraryCardAction action)
  onSelectedAction;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: characters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final character = characters[index];
        return LibraryGridItem(
          character: character,
          isDeleting: deletingCharacterId == character.id,
          onTap: () => onTapCharacter(character),
          onSelectedAction: (action) => onSelectedAction(character, action),
        );
      },
    );
  }
}

class LibraryGridItem extends StatelessWidget {
  const LibraryGridItem({
    super.key,
    required this.character,
    required this.isDeleting,
    required this.onTap,
    required this.onSelectedAction,
  });

  final Character character;
  final bool isDeleting;
  final VoidCallback onTap;
  final ValueChanged<LibraryCardAction> onSelectedAction;

  @override
  Widget build(BuildContext context) {
    return CharacterThumbnailCard(
      character: character,
      isDeleting: isDeleting,
      onTap: onTap,
      topRightAction: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: PopupMenuButton<LibraryCardAction>(
          tooltip: '관리 메뉴',
          enabled: !isDeleting,
          icon: const Icon(Icons.more_vert),
          onSelected: onSelectedAction,
          itemBuilder: (context) => const [
            PopupMenuItem(value: LibraryCardAction.delete, child: Text('삭제')),
          ],
        ),
      ),
    );
  }
}
