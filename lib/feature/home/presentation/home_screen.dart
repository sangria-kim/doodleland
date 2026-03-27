import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../library/presentation/library_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryViewModelProvider);

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '그림놀이터',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Text(
                    '그림을 선택하고, 무대에서 마음대로 움직여보세요.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap + 8),
                  _HomeActionButton(
                    label: '그림 만들기',
                    icon: Icons.edit,
                    onPressed: () => context.push('/capture'),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  _HomeActionButton(
                    label: '놀이 시작',
                    icon: Icons.play_arrow,
                    tonal: true,
                    onPressed: libraryState.isLoading
                        ? null
                        : () => _startStage(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startStage(BuildContext context, WidgetRef ref) async {
    final viewModel = ref.read(libraryViewModelProvider.notifier);
    await viewModel.loadCharacters();

    final characters = ref.read(libraryViewModelProvider).characters;
    if (!context.mounted) {
      return;
    }

    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그림이 없어요. 먼저 그림을 만들어보세요.')),
      );
      context.push('/capture');
      return;
    }

    context.push('/stage/background');
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.tonal = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final button = tonal
        ? FilledButton.tonal(
            onPressed: onPressed,
            child: _HomeActionButtonContent(
              icon: icon,
              label: label,
            ),
          )
        : FilledButton(
            onPressed: onPressed,
            child: _HomeActionButtonContent(
              icon: icon,
              label: label,
            ),
          );

    return button;
  }
}

class _HomeActionButtonContent extends StatelessWidget {
  const _HomeActionButtonContent({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28),
        const SizedBox(width: 16),
        Text(label),
      ],
    );
  }
}
