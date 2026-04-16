import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/app_back_button.dart';
import '../../../core/theme/app_theme.dart';
import 'capture_viewmodel.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key, required this.previewImagePath});

  final String previewImagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(captureViewModelProvider);
    final previewFile = File(previewImagePath);
    final canPop = Navigator.of(context).canPop();

    Future<void> saveAndGo({
      required String label,
      required bool moveToCapture,
    }) async {
      if (state.isBusy) return;
      final savedResult = await ref
          .read(captureViewModelProvider.notifier)
          .saveCurrentImage(previewImagePath);
      if (!context.mounted) return;
      if (savedResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.feedbackMessage ??
                  CaptureViewModel.recognitionFailureMessage,
            ),
          ),
        );
        return;
      }
      final warningMessage = savedResult.qualityWarningMessage;
      final suffix = warningMessage == null ? '' : ' ($warningMessage)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label 완료 (${savedResult.characterId})$suffix'),
        ),
      );
      if (moveToCapture) {
        context.go('/capture');
      } else {
        context.go('/');
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaQuery = MediaQuery.of(context);
                final gap = _responsiveGap(constraints.maxHeight);
                final buttonHeight = _responsiveButtonHeight(
                  constraints.maxHeight,
                );
                final buttonFont = _responsiveButtonFont(constraints.maxHeight);
                final imageSectionPadding = _responsiveImagePadding(
                  constraints.maxHeight,
                );

                return AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    left: AppSpacing.pageHorizontal,
                    right: AppSpacing.pageHorizontal,
                    top:
                        AppSpacing.pageVertical +
                        (canPop ? AppBackButtonOverlay.contentTopClearance : 0),
                    bottom:
                        AppSpacing.pageVertical + mediaQuery.viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: imageSectionPadding,
                          ),
                          child: Center(
                            child: previewFile.existsSync()
                                ? Image.file(previewFile, fit: BoxFit.contain)
                                : Text(previewImagePath),
                          ),
                        ),
                      ),
                      SizedBox(height: gap),
                      if (state.isBusy) ...[
                        const LinearProgressIndicator(minHeight: 3),
                        SizedBox(height: gap),
                      ],
                      SizedBox(
                        height: buttonHeight,
                        child: FilledButton(
                          onPressed: state.isBusy
                              ? null
                              : () => saveAndGo(
                                  label: '저장',
                                  moveToCapture: false,
                                ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(1),
                            textStyle: TextStyle(
                              fontSize: buttonFont,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('저장하기'),
                        ),
                      ),
                      SizedBox(height: gap),
                      SizedBox(
                        height: buttonHeight,
                        child: FilledButton(
                          onPressed: state.isBusy
                              ? null
                              : () => saveAndGo(
                                  label: '저장하고 하나 더',
                                  moveToCapture: true,
                                ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(1),
                            textStyle: TextStyle(
                              fontSize: buttonFont,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('저장하고 하나 더!'),
                        ),
                      ),
                      SizedBox(height: gap),
                      SizedBox(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: state.isBusy
                              ? null
                              : () => context.push('/capture'),
                          style: OutlinedButton.styleFrom(
                            textStyle: TextStyle(
                              fontSize: buttonFont,
                              fontWeight: FontWeight.w700,
                            ),
                            minimumSize: const Size.fromHeight(1),
                          ),
                          child: const Text('다시 찍기'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (canPop) const AppBackButtonOverlay(),
        ],
      ),
    );
  }

  static double _uiDensity(double screenHeight) {
    return (screenHeight / 640).clamp(0.62, 1.0);
  }

  static double _responsiveGap(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (14 * density).clamp(3.5, 14.0);
  }

  static double _responsiveButtonHeight(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (54 * density).clamp(28.0, 58.0);
  }

  static double _responsiveButtonFont(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (18 * density).clamp(11.0, 18.0);
  }

  static double _responsiveImagePadding(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (14 * density).clamp(0.0, 12.0);
  }
}
