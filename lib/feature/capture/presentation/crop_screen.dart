import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'capture_viewmodel.dart';

class CropScreen extends ConsumerStatefulWidget {
  const CropScreen({super.key, required this.sourceImagePath});

  final String sourceImagePath;

  @override
  ConsumerState<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends ConsumerState<CropScreen> {
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _runCrop();
      }
    });
  }

  Future<void> _runCrop() async {
    if (_isWorking || widget.sourceImagePath.isEmpty) return;
    if (!File(widget.sourceImagePath).existsSync()) return;

    setState(() {
      _isWorking = true;
    });

    try {
      final result = await ref
          .read(captureViewModelProvider.notifier)
          .cropImage(widget.sourceImagePath);
      if (!mounted) {
        return;
      }

      if (result == null) {
        final currentState = ref.read(captureViewModelProvider);
        if (currentState.feedbackMessage == '이미지 크롭이 취소되었습니다.') {
          context.go('/capture');
        } else if (currentState.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(currentState.feedbackMessage!)),
          );
        }
        return;
      }

      ref.read(captureViewModelProvider.notifier).clearFeedback();
      context.push('/capture/preview', extra: result);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureViewModelProvider);
    final sourceExists = File(widget.sourceImagePath).existsSync();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('이미지 크롭')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mediaQuery = MediaQuery.of(context);
            final gap = _responsiveGap(constraints.maxHeight);
            final buttonHeight = _responsiveButtonHeight(constraints.maxHeight);
            final buttonFont = _responsiveButtonFont(constraints.maxHeight);
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
                    '이미지를 자르기 화면으로 이동 중입니다.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: bodyFont,
                    ),
                  ),
                  SizedBox(height: gap),
                  if (!sourceExists) ...[
                    Text(
                      '원본 이미지가 없습니다. ${widget.sourceImagePath}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: bodyFont,
                      ),
                    ),
                    SizedBox(height: gap),
                  ],
                  Expanded(
                    child: Center(
                      child: sourceExists
                          ? Image.file(File(widget.sourceImagePath), fit: BoxFit.contain)
                          : const Text('선택한 이미지를 찾을 수 없습니다.'),
                    ),
                  ),
                  if (state.isBusy || _isWorking) ...[
                    SizedBox(height: gap),
                    const LinearProgressIndicator(minHeight: 3),
                    SizedBox(height: gap),
                  ] else
                    SizedBox(height: gap * 0.4),
                  SizedBox(
                    height: buttonHeight,
                    child: FilledButton(
                      onPressed: sourceExists && !_isWorking
                          ? () => _runCrop()
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(1),
                        textStyle: TextStyle(
                          fontSize: buttonFont,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('크롭 다시 실행'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static double _uiDensity(double screenHeight) {
    return (screenHeight / 640).clamp(0.62, 1.0);
  }

  static double _responsiveGap(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (14 * density).clamp(3.0, 14.0);
  }

  static double _responsiveButtonHeight(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (50 * density).clamp(28.0, 58.0);
  }

  static double _responsiveButtonFont(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (18 * density).clamp(11.0, 18.0);
  }

  static double _responsiveBodySize(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (18 * density).clamp(12.0, 18.0);
  }
}
