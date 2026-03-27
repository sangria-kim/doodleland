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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mediaQuery = MediaQuery.of(context);
            final titleFont = _responsiveTitleSize(constraints.maxHeight);
            final bodyFont = _responsiveBodySize(constraints.maxHeight);
            final gap = _responsiveGap(constraints.maxHeight);
            final buttonHeight = _responsiveButtonHeight(constraints.maxHeight);
            final buttonFont = _responsiveButtonFont(constraints.maxHeight);
            final buttonIconSize = _responsiveIconSize(constraints.maxHeight);

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: AppSpacing.pageHorizontal,
                right: AppSpacing.pageHorizontal,
                top: AppSpacing.pageVertical,
                bottom: AppSpacing.pageVertical + mediaQuery.viewInsets.bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '그림놀이터',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: titleFont,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: gap),
                      Text(
                        '그림을 선택하고, 무대에서 마음대로 움직여보세요.',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: bodyFont,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: buttonHeight,
                        child: _HomeActionButton(
                          label: '그림 만들기',
                          icon: Icons.edit,
                          buttonFontSize: buttonFont,
                          iconSize: buttonIconSize,
                          onPressed: () => context.push('/capture'),
                        ),
                      ),
                      SizedBox(height: gap),
                      SizedBox(
                        height: buttonHeight,
                        child: _HomeActionButton(
                          label: '놀이 시작',
                          icon: Icons.play_arrow,
                          tonal: true,
                          buttonFontSize: buttonFont,
                          iconSize: buttonIconSize,
                          onPressed: libraryState.isLoading
                              ? null
                              : () => _startStage(context, ref),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _uiDensity(double screenHeight) {
    return (screenHeight / 640).clamp(0.62, 1.0);
  }

  double _responsiveTitleSize(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (42 * density).clamp(22.0, 42.0);
  }

  double _responsiveBodySize(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (20 * density).clamp(13.0, 20.0);
  }

  double _responsiveGap(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (20 * density).clamp(6.0, 20.0);
  }

  double _responsiveButtonHeight(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (64 * density).clamp(40.0, 64.0);
  }

  double _responsiveButtonFont(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (22 * density).clamp(13.0, 22.0);
  }

  double _responsiveIconSize(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (28 * density).clamp(16.0, 28.0);
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
    required this.buttonFontSize,
    required this.iconSize,
    this.onPressed,
    this.tonal = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool tonal;
  final double buttonFontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final button = tonal
        ? FilledButton.tonal(
            onPressed: onPressed,
            child: _HomeActionButtonContent(
              icon: icon,
              label: label,
              buttonFontSize: buttonFontSize,
              iconSize: iconSize,
            ),
          )
        : FilledButton(
            onPressed: onPressed,
            child: _HomeActionButtonContent(
              icon: icon,
              label: label,
              buttonFontSize: buttonFontSize,
              iconSize: iconSize,
            ),
          );

    return button;
  }
}

class _HomeActionButtonContent extends StatelessWidget {
  const _HomeActionButtonContent({
    required this.icon,
    required this.label,
    required this.buttonFontSize,
    required this.iconSize,
  });

  final IconData icon;
  final String label;
  final double buttonFontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize),
        const SizedBox(width: 16),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: buttonFontSize,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
