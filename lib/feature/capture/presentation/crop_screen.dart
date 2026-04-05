import 'dart:async';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/image_processor.dart';
import 'capture_viewmodel.dart';
import 'crop_screen_args.dart';

const double _controlButtonSize = 46;

enum CropAspectPreset { free, square, ratio4x3, ratio16x9 }

extension on CropAspectPreset {
  String get label {
    switch (this) {
      case CropAspectPreset.free:
        return '자유';
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
  const CropScreen({super.key, required this.args});

  final CropScreenArgs args;

  @override
  ConsumerState<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends ConsumerState<CropScreen> {
  CropController _cropController = CropController();

  EditableImageData? _originalImage;
  EditableImageData? _workingImage;
  CropAspectPreset _selectedPreset = CropAspectPreset.free;
  CropStatus? _cropStatus;
  Rect? _viewportCropRect;
  int _editorRevision = 0;
  bool _isPreparing = true;
  bool _isSavingCrop = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadImage());
  }

  Future<void> _loadImage() async {
    if (widget.args.sourceImagePath.isEmpty) {
      setState(() {
        _isPreparing = false;
        _errorMessage = '원본 이미지 경로가 비어 있습니다.';
      });
      return;
    }

    try {
      final imageProcessor = ref.read(imageProcessorProvider);
      final editableImage = await imageProcessor.loadEditableImage(
        widget.args.sourceImagePath,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _originalImage = editableImage;
        _workingImage = editableImage;
        _selectedPreset = CropAspectPreset.free;
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
    switch (_selectedPreset) {
      case CropAspectPreset.free:
        return null;
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
      return '-';
    }

    if (_selectedPreset != CropAspectPreset.free) {
      return _selectedPreset.label;
    }

    final rect = _viewportCropRect;
    if (rect == null || rect.height == 0) {
      return CropAspectPreset.free.label;
    }
    return _formatAspectRatio(rect.width / rect.height);
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
    const height = 100;
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

  Future<void> _confirmAndResetAll() async {
    final originalImage = _originalImage;
    if (_isBusy || originalImage == null) {
      return;
    }

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          elevation: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360, minWidth: 300),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Material(
                  color: const Color(0xFFF0F0F2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(26, 30, 26, 24),
                        child: Text(
                          '변경사항을 모두 취소하고 원본 이미지로 복원 할까요?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFDADADF)),
                      SizedBox(
                        height: 60,
                        child: Row(
                          children: [
                            _DialogTextAction(
                              text: '취소',
                              onTap: () => Navigator.of(context).pop(false),
                            ),
                            Container(width: 1, color: const Color(0xFFDADADF)),
                            _DialogTextAction(
                              text: '원본 복원',
                              onTap: () => Navigator.of(context).pop(true),
                              emphasized: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (shouldRestore != true || !mounted) {
      return;
    }

    setState(() {
      _workingImage = originalImage;
      _selectedPreset = CropAspectPreset.free;
      _errorMessage = null;
      _rebuildEditor();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Rect _buildDetectedInitialRect(Rect viewportRect, Rect imageRect) {
    final fallback = viewportRect.deflate(16);
    final detectionResult = widget.args.detectionResult;
    if (!detectionResult.detected) {
      return fallback;
    }

    final normalized = _normalizeRect(detectionResult.boundingBox);
    if (normalized.width <= 0 || normalized.height <= 0) {
      return fallback;
    }

    final candidate = Rect.fromLTRB(
      imageRect.left + normalized.left * imageRect.width,
      imageRect.top + normalized.top * imageRect.height,
      imageRect.left + normalized.right * imageRect.width,
      imageRect.top + normalized.bottom * imageRect.height,
    ).intersect(imageRect);

    if (candidate.width < 24 || candidate.height < 24) {
      return fallback;
    }
    return candidate;
  }

  Rect _normalizeRect(Rect rect) {
    final left = rect.left.clamp(0.0, 1.0).toDouble();
    final top = rect.top.clamp(0.0, 1.0).toDouble();
    final right = rect.right.clamp(0.0, 1.0).toDouble();
    final bottom = rect.bottom.clamp(0.0, 1.0).toDouble();
    if (right <= left || bottom <= top) {
      return Rect.zero;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final layoutKey = isTablet
              ? const ValueKey('crop-tablet-layout')
              : isLandscape
              ? const ValueKey('crop-landscape-layout')
              : const ValueKey('crop-portrait-layout');
          final sidePanelWidth = isTablet ? 72.0 : 66.0;
          final overlayRightInset = (sidePanelWidth - _controlButtonSize) / 2;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
              child: Stack(
                children: [
                  Row(
                    key: layoutKey,
                    children: [
                      Expanded(child: _buildEditorStage()),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: sidePanelWidth,
                        child: _AspectPresetPanel(
                          presets: CropAspectPreset.values,
                          selectedPreset: _selectedPreset,
                          onSelected: _selectPreset,
                          isBusy: _isBusy,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: overlayRightInset,
                    child: _TopOverlayControls(
                      isBusy: _isBusy,
                      onClose: () => context.go('/capture'),
                      onRotate: _rotateImage,
                      onReset: _confirmAndResetAll,
                      onApply: _applyCrop,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditorStage() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(child: _buildCropEditor()),
            Positioned(
              top: 62,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: _CropInfoChip(
                    key: const ValueKey('crop-ratio-text'),
                    ratioText: _currentRatioText(),
                  ),
                ),
              ),
            ),
            if (_isBusy)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2.5),
              ),
            if (_errorMessage != null && _workingImage != null && !_isPreparing)
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: _InlineErrorChip(message: _errorMessage!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropEditor() {
    final workingImage = _workingImage;
    if (_isPreparing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (workingImage == null) {
      return Center(
        child: Text(
          _errorMessage ?? '이미지를 불러오지 못했습니다.',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    final fixedRatio = _selectedPreset != CropAspectPreset.free;
    final aspectRatio = _currentAspectRatio();

    return Crop(
      key: ValueKey('crop-editor-$_editorRevision-${_selectedPreset.name}'),
      image: workingImage.bytes,
      controller: _cropController,
      aspectRatio: aspectRatio,
      initialRectBuilder: aspectRatio == null
          ? InitialRectBuilder.withBuilder(_buildDetectedInitialRect)
          : InitialRectBuilder.withSizeAndRatio(
              size: 1,
              aspectRatio: aspectRatio,
            ),
      baseColor: const Color(0xFF131A20),
      maskColor: Colors.black.withValues(alpha: 0.48),
      radius: 22,
      interactive: !_isBusy,
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
    );
  }
}

class _TopOverlayControls extends StatelessWidget {
  const _TopOverlayControls({
    required this.isBusy,
    required this.onClose,
    required this.onRotate,
    required this.onReset,
    required this.onApply,
  });

  final bool isBusy;
  final VoidCallback onClose;
  final VoidCallback onRotate;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OverlayIconButton(
          buttonKey: const ValueKey('crop-close-btn'),
          icon: Icons.close_rounded,
          tooltip: '닫기',
          onPressed: isBusy ? null : onClose,
        ),
        const Spacer(),
        _OverlayIconButton(
          buttonKey: const ValueKey('crop-rotate-btn'),
          icon: Icons.rotate_90_degrees_cw_rounded,
          tooltip: '회전',
          onPressed: isBusy ? null : onRotate,
        ),
        const SizedBox(width: 8),
        _OverlayIconButton(
          buttonKey: const ValueKey('crop-reset-btn'),
          icon: Icons.refresh_rounded,
          tooltip: '초기화',
          onPressed: isBusy ? null : onReset,
        ),
        const SizedBox(width: 8),
        _OverlayIconButton(
          buttonKey: const ValueKey('crop-apply-btn'),
          icon: Icons.check_rounded,
          tooltip: '적용',
          onPressed: isBusy ? null : onApply,
          primary: true,
        ),
      ],
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.primary = false,
  });

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = primary
        ? AppPalette.primaryDark.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.32);
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        key: buttonKey,
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 22),
        color: Colors.white,
        splashRadius: 24,
        constraints: const BoxConstraints.tightFor(
          width: _controlButtonSize,
          height: _controlButtonSize,
        ),
      ),
    );
  }
}

class _CropInfoChip extends StatelessWidget {
  const _CropInfoChip({super.key, required this.ratioText});

  final String ratioText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          ratioText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AspectPresetPanel extends StatelessWidget {
  const _AspectPresetPanel({
    required this.presets,
    required this.selectedPreset,
    required this.onSelected,
    required this.isBusy,
  });

  final List<CropAspectPreset> presets;
  final CropAspectPreset selectedPreset;
  final ValueChanged<CropAspectPreset> onSelected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < presets.length; index++) ...[
                _AspectPresetButton(
                  preset: presets[index],
                  isSelected: selectedPreset == presets[index],
                  onPressed: isBusy ? null : () => onSelected(presets[index]),
                ),
                if (index != presets.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
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
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      child: FilledButton(
        key: ValueKey('aspect-${preset.name}'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.square(_controlButtonSize),
          maximumSize: const Size.square(_controlButtonSize),
          padding: EdgeInsets.zero,
          backgroundColor: isSelected
              ? AppPalette.primaryDark
              : const Color(0xFF2D333A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: Text(preset.label),
      ),
    );
  }
}

class _DialogTextAction extends StatelessWidget {
  const _DialogTextAction({
    required this.text,
    required this.onTap,
    this.emphasized = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
              color: emphasized ? Colors.black : const Color(0xFF2C2C30),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineErrorChip extends StatelessWidget {
  const _InlineErrorChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
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
