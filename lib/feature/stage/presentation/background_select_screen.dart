import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/app_back_button.dart';
import '../domain/model/stage_background.dart';
import 'stage_viewmodel.dart';

class BackgroundSelectScreen extends ConsumerWidget {
  const BackgroundSelectScreen({super.key, this.onBackgroundSelected});

  final ValueChanged<StageBackground>? onBackgroundSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                16 + AppBackButtonOverlay.contentTopClearance,
                16,
                16,
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.714,
                ),
                itemCount: defaultStageBackgrounds.length,
                itemBuilder: (context, index) {
                  final background = defaultStageBackgrounds[index];
                  return _BackgroundCard(
                    key: ValueKey(background.id),
                    background: background,
                    onTap: () => _handleBackgroundTap(context, ref, background),
                  );
                },
              ),
            ),
          ),
          AppBackButtonOverlay(onPressed: () => _close(context)),
        ],
      ),
    );
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/stage');
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
                errorBuilder: (context, error, stackTrace) {
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
                  color: Colors.black.withValues(alpha: 0.6),
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
