import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MenuActionButton extends StatelessWidget {
  const MenuActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.buttonFontSize,
    required this.buttonIconSize,
    this.backgroundColor = AppPalette.primary,
    this.disabledBackgroundColor = const Color(0xFFC8CDD2),
    this.borderColor = const Color(0x42FFFFFF),
    this.borderWidth = 1.5,
    this.shadowColor = AppPalette.primary,
    this.disabledForegroundColor = const Color(0x8AFFFFFF),
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.spacing = 12,
    this.borderRadius = 30,
    this.shadowOpacity = 0.26,
    this.backgroundOpacity = 0.8,
    this.splashOpacity = 0.16,
    this.fontFamily = AppFontFamilies.yoonChildfundkoreaMinGuk,
    this.onForegroundColor = AppPalette.onPrimary,
    this.fontWeight = FontWeight.bold,
    this.textHeight = 1.2,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double buttonFontSize;
  final double buttonIconSize;
  final Color backgroundColor;
  final Color disabledBackgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final Color disabledForegroundColor;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double borderRadius;
  final double shadowOpacity;
  final double backgroundOpacity;
  final double splashOpacity;
  final String fontFamily;
  final Color onForegroundColor;
  final FontWeight fontWeight;
  final double textHeight;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final activeColor = isEnabled
        ? backgroundColor.withValues(alpha: backgroundOpacity)
        : disabledBackgroundColor;

    final foregroundColor = isEnabled
        ? onForegroundColor
        : disabledForegroundColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppPalette.primary.withValues(alpha: splashOpacity),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: activeColor,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: shadowOpacity),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: SizedBox.expand(
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: buttonIconSize, color: foregroundColor),
                  SizedBox(width: spacing),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foregroundColor,
                        fontFamily: fontFamily,
                        fontSize: buttonFontSize,
                        fontWeight: fontWeight,
                        height: textHeight,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
