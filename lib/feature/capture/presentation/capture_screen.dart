import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'capture_viewmodel.dart';

class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('그림 가져오기')),
      body: _CaptureScreenBody(),
    );
  }
}

class _CaptureScreenBody extends ConsumerStatefulWidget {
  const _CaptureScreenBody();

  @override
  ConsumerState<_CaptureScreenBody> createState() => _CaptureScreenBodyState();
}

class _CaptureScreenBodyState extends ConsumerState<_CaptureScreenBody> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureViewModelProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final buttonHeight = _responsiveButtonHeight(constraints.maxHeight);
          final gap = _responsiveGap(constraints.maxHeight);
          final buttonFont = _responsiveButtonFont(constraints.maxHeight);
          final buttonIconSize = _responsiveIconSize(constraints.maxHeight);
          final buttonWidth = _responsiveButtonWidth(constraints.maxWidth, gap);

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: AppSpacing.pageHorizontal,
              right: AppSpacing.pageHorizontal,
              top: AppSpacing.pageVertical,
              bottom: AppSpacing.pageVertical + mediaQuery.viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.hasFeedback) ...[
                  _FeedbackBanner(message: state.feedbackMessage!),
                  SizedBox(height: gap),
                ],
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
                            child: _SourceButton(
                              label: '카메라로 찍기',
                              icon: Icons.camera_alt,
                              buttonFontSize: buttonFont,
                              buttonIconSize: buttonIconSize,
                              onPressed: state.isBusy
                                  ? null
                                  : () => _onPick(
                                      context,
                                      CaptureImageSource.camera,
                                    ),
                            ),
                          ),
                          SizedBox(width: gap),
                          SizedBox(
                            width: buttonWidth,
                            height: buttonHeight,
                            child: _SourceButton(
                              label: '갤러리에서 선택',
                              icon: Icons.photo_library,
                              buttonFontSize: buttonFont,
                              buttonIconSize: buttonIconSize,
                              onPressed: state.isBusy
                                  ? null
                                  : () => _onPick(
                                      context,
                                      CaptureImageSource.gallery,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (state.isBusy) ...[
                  SizedBox(height: gap),
                  const LinearProgressIndicator(minHeight: 3),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  double _uiDensity(double screenHeight) {
    return (screenHeight / 640).clamp(0.62, 1.0);
  }

  double _responsiveButtonHeight(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (88 * density * 2).clamp(124.0, 196.0);
  }

  double _responsiveGap(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (20 * density).clamp(4.0, AppSpacing.sectionGap.toDouble());
  }

  double _responsiveButtonFont(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (30 * density).clamp(18.0, 30.0);
  }

  double _responsiveButtonWidth(double screenWidth, double gap) {
    final available = (screenWidth - gap);
    return (available * 0.35).clamp(180.0, 420.0);
  }

  double _responsiveIconSize(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (36 * density).clamp(21.0, 36.0);
  }

  Future<void> _onPick(BuildContext context, CaptureImageSource source) async {
    final cropArgs = await ref
        .read(captureViewModelProvider.notifier)
        .pickImageAndDetect(source);
    if (!context.mounted) return;
    if (cropArgs == null) return;
    ref.read(captureViewModelProvider.notifier).clearFeedback();
    if (!context.mounted) return;
    context.push('/capture/crop', extra: cropArgs);
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.buttonFontSize,
    required this.buttonIconSize,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double buttonFontSize;
  final double buttonIconSize;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        splashColor: AppPalette.primary.withValues(alpha: 0.16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isEnabled ? AppPalette.primary : const Color(0xFFC8CDD2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.26),
              width: 1.5,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppPalette.primary.withValues(alpha: 0.26),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: buttonIconSize,
                    color: isEnabled
                        ? AppPalette.onPrimary
                        : AppPalette.onPrimary.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isEnabled
                          ? AppPalette.onPrimary
                          : AppPalette.onPrimary.withValues(alpha: 0.55),
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w700,
                    ),
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

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.orange.shade100,
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.brown),
      ),
    );
  }
}
