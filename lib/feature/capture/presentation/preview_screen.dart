import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'capture_viewmodel.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key, required this.previewImagePath});

  final String previewImagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(captureViewModelProvider);
    final previewFile = File(previewImagePath);

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
          SnackBar(content: Text(state.feedbackMessage ?? '저장 실패')),
        );
        return;
      }
      final warningMessage = savedResult.qualityWarningMessage;
      final suffix = warningMessage == null ? '' : ' ($warningMessage)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 완료 (${savedResult.characterId})$suffix')),
      );
      if (moveToCapture) {
        context.go('/capture');
      } else {
        context.go('/');
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('미리보기')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: previewFile.existsSync()
                      ? Image.file(previewFile, fit: BoxFit.contain)
                      : Text(previewImagePath),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (state.isBusy) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
              FilledButton(
                onPressed: state.isBusy ? null : () => saveAndGo(label: '저장', moveToCapture: false),
                child: const Text('저장하기'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed:
                    state.isBusy ? null : () => saveAndGo(label: '저장하고 하나 더', moveToCapture: true),
                child: const Text('저장하고 하나 더!'),
              ),
                const SizedBox(height: 12),
              OutlinedButton(
                onPressed: state.isBusy ? null : () => context.push('/capture'),
                child: const Text('다시 찍기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
