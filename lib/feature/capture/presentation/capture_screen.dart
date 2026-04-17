import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/app_back_button.dart';
import '../../../core/presentation/entry_background_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/menu_action_button.dart';
import 'capture_viewmodel.dart';

class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPop = Navigator.of(context).canPop();

    return EntryBackgroundScaffold(
      showBackButton: canPop,
      body: _CaptureScreenBody(showBackButton: canPop),
    );
  }
}

class _CaptureScreenBody extends ConsumerStatefulWidget {
  const _CaptureScreenBody({required this.showBackButton});

  final bool showBackButton;

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
          final buttonGap = _responsiveButtonGap(constraints.maxWidth);
          final buttonFont = _responsiveButtonFont(constraints.maxHeight);
          final buttonIconSize = _responsiveIconSize(constraints.maxHeight);
          final actionButtonWidth = _responsiveActionButtonWidth(
            constraints.maxWidth,
          );

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: AppSpacing.pageHorizontal,
              right: AppSpacing.pageHorizontal,
              top:
                  AppSpacing.pageVertical +
                  (widget.showBackButton
                      ? AppBackButtonOverlay.contentTopClearance
                      : 0),
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
                            width: actionButtonWidth,
                            height: buttonHeight,
                            child: MenuActionButton(
                              label: '카메라로 찍기',
                              icon: Icons.camera_alt,
                              buttonFontSize: buttonFont,
                              buttonIconSize: buttonIconSize,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              onPressed: state.isBusy
                                  ? null
                                  : () => _onPick(
                                      context,
                                      CaptureImageSource.camera,
                                    ),
                            ),
                          ),
                          SizedBox(width: buttonGap),
                          SizedBox(
                            width: actionButtonWidth,
                            height: buttonHeight,
                            child: MenuActionButton(
                              label: '갤러리에서 선택',
                              icon: Icons.photo_library,
                              buttonFontSize: buttonFont,
                              buttonIconSize: buttonIconSize,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
    return screenHeight * 0.20;
  }

  double _responsiveGap(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (20 * density).clamp(4.0, AppSpacing.sectionGap.toDouble());
  }

  double _responsiveButtonFont(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (32 * density).clamp(19.0, 32.0);
  }

  double _responsiveActionButtonWidth(double screenWidth) {
    return screenWidth.clamp(0.0, 1080.0) * 0.25;
  }

  double _responsiveButtonGap(double screenWidth) {
    return screenWidth * 0.02;
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
