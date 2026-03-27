import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'capture_viewmodel.dart';

class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
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
    final theme = Theme.of(context);
    final state = ref.watch(captureViewModelProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final buttonHeight = _responsiveButtonHeight(constraints.maxHeight);
          final gap = _responsiveGap(constraints.maxHeight);
          final buttonFont = _responsiveButtonFont(constraints.maxHeight);
          final titleFont = _responsiveTitleSize(constraints.maxHeight);
          final bodyFont = _responsiveBodySize(constraints.maxHeight);

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
                Text(
                  '그림 가져오기',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: titleFont,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: gap),
                if (state.hasFeedback) ...[
                  _FeedbackBanner(message: state.feedbackMessage!),
                  SizedBox(height: gap),
                ],
                Text(
                  '카메라로 새로 찍거나 갤러리에서 기존 이미지를 선택해 다음 단계로 넘어갑니다.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: bodyFont,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: buttonHeight,
                  child: _SourceButton(
                    label: '카메라로 찍기',
                    icon: Icons.camera_alt,
                    buttonFontSize: buttonFont,
                    onPressed:
                        state.isBusy ? null : () => _onPick(context, CaptureImageSource.camera),
                  ),
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: buttonHeight,
                  child: _SourceButton(
                    label: '갤러리에서 선택',
                    icon: Icons.photo_library,
                    buttonFontSize: buttonFont,
                    onPressed:
                        state.isBusy ? null : () => _onPick(context, CaptureImageSource.gallery),
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
    return (screenHeight / 620).clamp(0.68, 1.0);
  }

  double _responsiveButtonHeight(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (52 * density).clamp(26.0, 52.0);
  }

  double _responsiveGap(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (20 * density).clamp(4.0, AppSpacing.sectionGap.toDouble());
  }

  double _responsiveButtonFont(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (20 * density).clamp(12.0, 18.0);
  }

  double _responsiveTitleSize(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (36 * density).clamp(20.0, 36.0);
  }

  double _responsiveBodySize(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (18 * density).clamp(11.0, 18.0);
  }

  Future<void> _onPick(BuildContext context, CaptureImageSource source) async {
    final selectedImage = await ref
        .read(captureViewModelProvider.notifier)
        .pickImage(source);
    if (!mounted) return;
    if (selectedImage == null) return;
    ref.read(captureViewModelProvider.notifier).clearFeedback();
    if (!mounted) return;
    context.push('/capture/crop', extra: selectedImage);
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.buttonFontSize,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double buttonFontSize;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(1),
        padding: EdgeInsets.symmetric(
          vertical: (buttonFontSize * 0.45).clamp(4.0, 12.0),
          horizontal: 12,
        ),
        textStyle: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: (buttonFontSize + 4).clamp(14.0, 24.0)),
          const SizedBox(width: 12),
          Text(label),
        ],
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
