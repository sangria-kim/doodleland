import 'package:flutter/material.dart';

import '../constants/app_asset_paths.dart';

class AppBackIcon extends StatelessWidget {
  const AppBackIcon({super.key, this.size = 40, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssetPaths.backIcon,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      semanticLabel: '뒤로 가기',
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.tooltip = '뒤로 가기',
    this.iconSize = 40,
    this.style,
    this.iconColor,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final double iconSize;
  final ButtonStyle? style;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ).merge(style),
      icon: AppBackIcon(size: iconSize, color: iconColor),
    );
  }
}

class AppBackButtonOverlay extends StatelessWidget {
  const AppBackButtonOverlay({
    super.key,
    this.onPressed,
    this.iconColor,
    this.style,
  });

  static const double horizontalOffset = 16;
  static const double topOffset = 12;
  static const double contentTopClearance = 64;

  final VoidCallback? onPressed;
  final Color? iconColor;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: horizontalOffset,
      top: MediaQuery.paddingOf(context).top + topOffset,
      child: AppBackButton(
        onPressed: onPressed,
        iconColor: iconColor,
        style: style,
      ),
    );
  }
}
