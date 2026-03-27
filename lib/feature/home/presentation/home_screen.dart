import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => context.push('/stage/background'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tonal = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
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
