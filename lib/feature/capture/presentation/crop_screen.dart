import 'dart:async';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/image_processor.dart';
import 'capture_viewmodel.dart';

enum CropAspectPreset {
  free,
  original,
  square,
  ratio4x3,
  ratio16x9,
}

extension on CropAspectPreset {
  String get label {
    switch (this) {
      case CropAspectPreset.free:
        return '자유';
      case CropAspectPreset.original:
        return '원본';
      case CropAspectPreset.square:
        return '1:1';
      case CropAspectPreset.ratio4x3:
        return '4:3';
      case CropAspectPreset.ratio16x9:
        return '16:9';
    }
  }
}

class CropScreen extends ConsumerStatefulWidget {
  const CropScreen({super.key, required this.sourceImagePath});

  final String sourceImagePath;

  @override
  ConsumerState<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends ConsumerState<CropScreen> {
  CropController _cropController = CropController();

  EditableImageData? _originalImage;
  EditableImageData? _workingImage;
  CropAspectPreset _selectedPreset = CropAspectPreset.original;
  CropStatus? _cropStatus;
  Rect? _viewportCropRect;
  int _editorRevision = 0;
  int _rotationQuarterTurns = 0;
  bool _isPreparing = true;
  bool _isSavingCrop = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadImage());
  }

  Future<void> _loadImage() async {
    if (widget.sourceImagePath.isEmpty) {
      setState(() {
        _isPreparing = false;
        _errorMessage = '원본 이미지 경로가 비어 있습니다.';
      });
      return;
    }

    try {
      final imageProcessor = ref.read(imageProcessorProvider);
      final editableImage = await imageProcessor.loadEditableImage(
        widget.sourceImagePath,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _originalImage = editableImage;
        _workingImage = editableImage;
        _selectedPreset = CropAspectPreset.original;
        _isPreparing = false;
        _errorMessage = null;
        _rebuildEditor();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPreparing = false;
        _errorMessage = '이미지를 불러오지 못했습니다: $error';
      });
    }
  }

  bool get _isBusy {
    return _isPreparing ||
        _isSavingCrop ||
        _cropStatus == CropStatus.loading ||
        _cropStatus == CropStatus.cropping;
  }

  void _rebuildEditor() {
    _cropController = CropController();
    _viewportCropRect = null;
    _editorRevision++;
  }

  double? _currentAspectRatio() {
    final image = _workingImage;
    if (image == null) {
      return null;
    }

    switch (_selectedPreset) {
      case CropAspectPreset.free:
        return null;
      case CropAspectPreset.original:
        return image.aspectRatio;
      case CropAspectPreset.square:
        return 1;
      case CropAspectPreset.ratio4x3:
        return 4 / 3;
      case CropAspectPreset.ratio16x9:
        return 16 / 9;
    }
  }

  String _currentRatioText() {
    if (_workingImage == null) {
      return '이미지 준비 중';
    }

    if (_selectedPreset == CropAspectPreset.free) {
      final rect = _viewportCropRect;
      if (rect == null || rect.height == 0) {
        return '자유 비율';
      }
      return '자유 ${_formatAspectRatio(rect.width / rect.height)}';
    }

    return switch (_selectedPreset) {
      CropAspectPreset.original => '원본 ${_formatAspectRatio(_currentAspectRatio()!)}',
      CropAspectPreset.square => '1:1 고정',
      CropAspectPreset.ratio4x3 => '4:3 고정',
      CropAspectPreset.ratio16x9 => '16:9 고정',
      CropAspectPreset.free => '자유 비율',
    };
  }

  String _formatAspectRatio(double ratio) {
    if (ratio.isNaN || !ratio.isFinite || ratio <= 0) {
      return '-';
    }

    const commonRatios = <(String label, double value)>[
      ('1:1', 1),
      ('4:3', 4 / 3),
      ('3:2', 3 / 2),
      ('16:9', 16 / 9),
      ('9:16', 9 / 16),
    ];
    for (final ratioOption in commonRatios) {
      if ((ratio - ratioOption.$2).abs() < 0.03) {
        return ratioOption.$1;
      }
    }

    final width = (ratio * 100).round();
    final height = 100;
    final divisor = _gcd(width, height);
    final simplifiedWidth = width ~/ divisor;
    final simplifiedHeight = height ~/ divisor;
    if ((ratio - simplifiedWidth / simplifiedHeight).abs() < 0.03) {
      return '$simplifiedWidth:$simplifiedHeight';
    }
    return ratio.toStringAsFixed(2);
  }

  int _gcd(int a, int b) {
    var left = a.abs();
    var right = b.abs();
    while (right != 0) {
      final remainder = left % right;
      left = right;
      right = remainder;
    }
    return left == 0 ? 1 : left;
  }

  Future<void> _applyCrop() async {
    if (_isBusy || _workingImage == null) {
      return;
    }

    setState(() {
      _isSavingCrop = true;
      _errorMessage = null;
    });
    _cropController.crop();
  }

  Future<void> _handleCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        await _persistCroppedImage(croppedImage);
      case CropFailure(:final cause):
        if (!mounted) {
          return;
        }
        setState(() {
          _isSavingCrop = false;
          _errorMessage = '이미지 자르기에 실패했습니다: $cause';
        });
        _showMessage(_errorMessage!);
    }
  }

  Future<void> _persistCroppedImage(Uint8List croppedImage) async {
    try {
      final outputPath = await ref
          .read(imageProcessorProvider)
          .writeTemporaryPng(croppedImage);
      if (!mounted) {
        return;
      }

      ref.read(captureViewModelProvider.notifier).clearFeedback();
      setState(() {
        _isSavingCrop = false;
      });
      context.push('/capture/preview', extra: outputPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingCrop = false;
        _errorMessage = '크롭 결과를 저장하지 못했습니다: $error';
      });
      _showMessage(_errorMessage!);
    }
  }

  Future<void> _rotateImage() async {
    final image = _workingImage;
    if (_isBusy || image == null) {
      return;
    }

    setState(() {
      _isPreparing = true;
      _errorMessage = null;
    });

    try {
      final rotated = await ref
          .read(imageProcessorProvider)
          .rotateClockwise(image.bytes);
      if (!mounted) {
        return;
      }

      setState(() {
        _workingImage = rotated;
        _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
        _isPreparing = false;
        _rebuildEditor();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPreparing = false;
        _errorMessage = '회전에 실패했습니다: $error';
      });
      _showMessage(_errorMessage!);
    }
  }

  void _resetAll() {
    final originalImage = _originalImage;
    if (_isBusy || originalImage == null) {
      return;
    }

    setState(() {
      _workingImage = originalImage;
      _selectedPreset = CropAspectPreset.original;
      _rotationQuarterTurns = 0;
      _errorMessage = null;
      _rebuildEditor();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectPreset(CropAspectPreset preset) {
    if (_selectedPreset == preset || _workingImage == null || _isBusy) {
      return;
    }

    setState(() {
      _selectedPreset = preset;
      _errorMessage = null;
      _rebuildEditor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _isBusy ? null : () => context.go('/capture'),
          icon: const Icon(Icons.close_rounded),
          tooltip: '닫기',
        ),
        title: const Text('이미지 자르기'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isBusy ? null : _applyCrop,
              icon: const Icon(Icons.check_rounded),
              label: const Text('적용'),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.primaryDark,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final body = _buildResponsiveBody(
            isTablet: isTablet,
            isLandscape: isLandscape,
          );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InlineError(message: _errorMessage!),
                    ),
                  Expanded(child: body),
                  if (_isBusy)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveBody({
    required bool isTablet,
    required bool isLandscape,
  }) {
    final layoutKey = isTablet
        ? const ValueKey('crop-tablet-layout')
        : isLandscape
        ? const ValueKey('crop-landscape-layout')
        : const ValueKey('crop-portrait-layout');
    final useHorizontalControls = isTablet || isLandscape;

    return Column(
      key: layoutKey,
      children: [
        Expanded(
          child: _CropCanvasCard(
            child: Stack(
              children: [
                Positioned.fill(child: _buildCropEditor()),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _CropInfoChip(
                    key: const ValueKey('crop-ratio-text'),
                    ratioText: _currentRatioText(),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _CropHintChip(
                    text: _selectedPreset == CropAspectPreset.free
                        ? '자유 크롭'
                        : '고정 비율',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ControlBar(
          presets: CropAspectPreset.values,
          selectedPreset: _selectedPreset,
          onSelected: _selectPreset,
          onRotate: _rotateImage,
          onReset: _resetAll,
          isBusy: _isBusy,
          rotationQuarterTurns: _rotationQuarterTurns,
          horizontal: useHorizontalControls,
        ),
      ],
    );
  }

  Widget _buildCropEditor() {
    final workingImage = _workingImage;
    if (_isPreparing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (workingImage == null) {
      return const Center(
        child: Text(
          '이미지를 불러오지 못했습니다.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final fixedRatio = _selectedPreset != CropAspectPreset.free;
    final aspectRatio = _currentAspectRatio();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Crop(
        key: ValueKey('crop-editor-$_editorRevision-${_selectedPreset.name}'),
        image: workingImage.bytes,
        controller: _cropController,
        aspectRatio: aspectRatio,
        initialRectBuilder: aspectRatio == null
            ? InitialRectBuilder.withBuilder(
                (viewportRect, imageRect) => viewportRect.deflate(16),
              )
            : InitialRectBuilder.withSizeAndRatio(
                size: 1,
                aspectRatio: aspectRatio,
              ),
        baseColor: const Color(0xFFF4F8FB),
        maskColor: Colors.black.withValues(alpha: 0.42),
        radius: 20,
        interactive: fixedRatio,
        fixCropRect: fixedRatio,
        willUpdateScale: (newScale) => newScale >= 0.6 && newScale <= 4.0,
        filterQuality: FilterQuality.high,
        progressIndicator: const Center(child: CircularProgressIndicator()),
        onMoved: (viewportRect, imageRect) {
          setState(() {
            _viewportCropRect = viewportRect;
          });
        },
        onStatusChanged: (status) {
          setState(() {
            _cropStatus = status;
          });
        },
        overlayBuilder: (context, rect) {
          return CustomPaint(
            painter: _GridOverlayPainter(),
            child: const SizedBox.expand(),
          );
        },
        cornerDotBuilder: (size, edgeAlignment) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppPalette.primary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          );
        },
        onCropped: (result) {
          unawaited(_handleCropped(result));
        },
      ),
    );
  }
}

class _CropInfoChip extends StatelessWidget {
  const _CropInfoChip({
    super.key,
    required this.ratioText,
  });

  final String ratioText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7E2EA)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          ratioText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppPalette.textPrimary,
              ),
        ),
      ),
    );
  }
}

class _CropHintChip extends StatelessWidget {
  const _CropHintChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.presets,
    required this.selectedPreset,
    required this.onSelected,
    required this.onRotate,
    required this.onReset,
    required this.isBusy,
    required this.rotationQuarterTurns,
    required this.horizontal,
  });

  final List<CropAspectPreset> presets;
  final CropAspectPreset selectedPreset;
  final ValueChanged<CropAspectPreset> onSelected;
  final VoidCallback onRotate;
  final VoidCallback onReset;
  final bool isBusy;
  final int rotationQuarterTurns;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final ratioSection = _ControlSection(
      title: '비율',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final preset in presets) ...[
              _AspectPresetButton(
                preset: preset,
                isSelected: selectedPreset == preset,
                onPressed: () => onSelected(preset),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
    final actionSection = _ControlSection(
      title: '동작',
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.rotate_90_degrees_cw_rounded,
            label: rotationQuarterTurns == 0
                ? '회전'
                : '회전 ${rotationQuarterTurns * 90}°',
            onPressed: isBusy ? null : onRotate,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.refresh_rounded,
            label: '초기화',
            onPressed: isBusy ? null : onReset,
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E1E8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120E1C28),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: ratioSection),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: actionSection),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ratioSection,
                  const SizedBox(height: 10),
                  actionSection,
                ],
              ),
      ),
    );
  }
}

class _ControlSection extends StatelessWidget {
  const _ControlSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppPalette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CropCanvasCard extends StatelessWidget {
  const _CropCanvasCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD8E1E8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120E1C28),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
}

class _AspectPresetButton extends StatelessWidget {
  const _AspectPresetButton({
    required this.preset,
    required this.isSelected,
    required this.onPressed,
  });

  final CropAspectPreset preset;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      child: FilledButton(
        key: ValueKey('aspect-${preset.name}'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 42),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          backgroundColor: isSelected
              ? AppPalette.primary
              : const Color(0xFFF4F7FA),
          foregroundColor: isSelected ? Colors.white : AppPalette.textPrimary,
          elevation: isSelected ? 1 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : const Color(0xFFD8E1E8),
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(
          preset == CropAspectPreset.original && isSelected
              ? '${preset.label} 고정'
              : preset.label,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 42),
          foregroundColor: AppPalette.textPrimary,
          backgroundColor: const Color(0xFFF4F7FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD8E1E8)),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    final stepX = size.width / 3;
    final stepY = size.height / 3;

    for (var i = 1; i < 3; i++) {
      final dx = stepX * i;
      final dy = stepY * i;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
