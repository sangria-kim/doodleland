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
    _runCrop();
  }

  Future<void> _runCrop() async {
    if (_isWorking || widget.sourceImagePath.isEmpty) return;
    _isWorking = true;
    final result = await ref
        .read(captureViewModelProvider.notifier)
        .cropImage(widget.sourceImagePath);
    if (!mounted) return;
    _isWorking = false;
    if (result == null) {
      context.go('/capture');
      return;
    }
    ref.read(captureViewModelProvider.notifier).clearFeedback();
    context.push('/capture/preview', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureViewModelProvider);
    final sourceExists = File(widget.sourceImagePath).existsSync();

    return Scaffold(
      appBar: AppBar(title: const Text('이미지 크롭')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('이미지를 자르기 화면으로 이동 중입니다.'),
              const SizedBox(height: AppSpacing.sectionGap),
              if (!sourceExists) ...[
                Text('원본 이미지가 없습니다. ${widget.sourceImagePath}'),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
              Expanded(
                child: sourceExists
                    ? Image.file(
                        File(widget.sourceImagePath),
                        fit: BoxFit.contain,
                      )
                    : const Center(child: Text('선택한 이미지를 찾을 수 없습니다.')),
              ),
              if (state.isBusy) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
              FilledButton(
                onPressed: sourceExists ? () => _runCrop() : null,
                child: const Text('크롭 다시 실행'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
