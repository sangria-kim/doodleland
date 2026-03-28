import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/model/stage_background.dart';
import 'stage_viewmodel.dart';

class BackgroundSelectScreen extends ConsumerWidget {
  const BackgroundSelectScreen({super.key, this.onBackgroundSelected});

  final ValueChanged<StageBackground>? onBackgroundSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('배경 고르기')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('무대 배경', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: defaultStageBackgrounds.length,
                  itemBuilder: (context, index) {
                    final background = defaultStageBackgrounds[index];
                    return _BackgroundCard(
                      key: ValueKey(background.id),
                      background: background,
                      onTap: () =>
                          _handleBackgroundTap(context, ref, background),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBackgroundTap(
    BuildContext context,
    WidgetRef ref,
    StageBackground background,
  ) {
    if (onBackgroundSelected != null) {
      onBackgroundSelected!(background);
      return;
    }

    ref.read(stageViewModelProvider.notifier).selectBackground(background);
    context.go('/stage');

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(background);
    }
  }
}

class _BackgroundCard extends StatelessWidget {
  const _BackgroundCard({
    super.key,
    required this.background,
    required this.onTap,
  });

  final StageBackground background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        key: ValueKey('background-tile-${background.id}'),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                background.assetPath,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                errorBuilder: (context, _, __) {
                  return const ColoredBox(color: Colors.black12);
                },
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    background.name,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
