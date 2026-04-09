import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/stage_audio_controller.dart';
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
                    final buttonWidth = _responsiveButtonWidth(
                      constraints.maxWidth,
                      gap,
                    );
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
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: buttonWidth,
                                  height: buttonHeight,
                                  child: _HomeActionButton(
                                    label: '그림 만들기',
                                    icon: Icons.edit,
                                    buttonFontSize: buttonFont,
                                    iconSize: buttonIconSize,
                                    onPressed: () => _startCreate(context, ref),
                                  ),
                                ),
                                SizedBox(width: gap),
                                SizedBox(
                                  width: buttonWidth,
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
                          ],
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
    return (88 * density * 2).clamp(124.0, 196.0);
  }

  double _responsiveButtonWidth(double screenWidth, double gap) {
    final available = screenWidth - gap;
    return (available * 0.35).clamp(180.0, 420.0);
  }

  double _responsiveButtonFont(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (30 * density).clamp(18.0, 30.0);
  }

  double _responsiveIconSize(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (36 * density).clamp(21.0, 36.0);
  }

  Future<void> _startStage(BuildContext context, WidgetRef ref) async {
    await ref.read(stageAudioControllerProvider).playHomePlayButtonSfx();

    final viewModel = ref.read(libraryViewModelProvider.notifier);
    await viewModel.loadCharacters();

    final characters = ref.read(libraryViewModelProvider).characters;
    if (!context.mounted) {
      return;
    }

    if (characters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('그림이 없어요. 먼저 그림을 만들어보세요.')));
      context.push('/capture');
      return;
    }

    context.push('/stage/background');
  }

  Future<void> _startCreate(BuildContext context, WidgetRef ref) async {
    await ref.read(stageAudioControllerProvider).playHomeCreateButtonSfx();

    if (!context.mounted) {
      return;
    }

    context.push('/capture');
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
    final isEnabled = onPressed != null;
    final isPrimary = !tonal;
    final borderRadius = BorderRadius.circular(30);
    final buttonBackground = isPrimary
        ? AppPalette.primary
        : const Color(0xFF53B4A0);
    final buttonForeground = AppPalette.onPrimary;
    final disabledBackground = isPrimary
        ? const Color(0xFFC8CDD2)
        : const Color(0xFFDDE3E6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        splashColor: AppPalette.primary.withOpacity(0.16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: isEnabled ? buttonBackground : disabledBackground,
            border: Border.all(
              color: isPrimary
                  ? Colors.white.withOpacity(0.26)
                  : Colors.white.withOpacity(0.30),
              width: isPrimary ? 1.5 : 1.2,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: (isPrimary ? AppPalette.primary : AppPalette.textSecondary)
                          .withOpacity(0.26),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _HomeActionButtonContent(
                icon: icon,
                label: label,
                buttonFontSize: buttonFontSize,
                iconSize: iconSize,
                color: buttonForeground.withOpacity(isEnabled ? 1 : 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeActionButtonContent extends StatelessWidget {
  const _HomeActionButtonContent({
    required this.icon,
    required this.label,
    required this.buttonFontSize,
    required this.iconSize,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double buttonFontSize;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 18),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: buttonFontSize,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
