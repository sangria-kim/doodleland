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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
          vertical: AppSpacing.pageVertical,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('그림 가져오기', style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.sectionGap),
            if (state.hasFeedback) ...[
              _FeedbackBanner(message: state.feedbackMessage!),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            Text(
              '카메라로 새로 찍거나 갤러리에서 기존 이미지를 선택해 다음 단계로 넘어갑니다.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.sectionGap + 8),
            _SourceButton(
              label: '카메라로 찍기',
              icon: Icons.camera_alt,
              onPressed: state.isBusy ? null : () => _onPick(context, CaptureImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _SourceButton(
              label: '갤러리에서 선택',
              icon: Icons.photo_library,
              onPressed: state.isBusy ? null : () => _onPick(context, CaptureImageSource.gallery),
            ),
            if (state.isBusy) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              const LinearProgressIndicator(minHeight: 3),
            ],
          ],
        ),
      ),
    );
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
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
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
        style: const TextStyle(color: Colors.brown),
      ),
    );
  }
}
