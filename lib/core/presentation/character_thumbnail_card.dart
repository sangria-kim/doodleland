import 'dart:io';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../theme/app_theme.dart';

class CharacterThumbnailCard extends StatelessWidget {
  const CharacterThumbnailCard({
    super.key,
    required this.character,
    this.onTap,
    this.isDeleting = false,
    this.topRightAction,
  });

  final Character character;
  final VoidCallback? onTap;
  final bool isDeleting;
  final Widget? topRightAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: colorScheme.surface,
            child: InkWell(
              onTap: isDeleting ? null : onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _CheckerboardTile(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.file(
                            File(character.thumbnailPath),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_outlined, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (topRightAction != null)
            Positioned(top: 8, right: 8, child: topRightAction!),
          if (isDeleting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckerboardTile extends StatelessWidget {
  const _CheckerboardTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _CheckerboardPainter(),
      child: SizedBox.expand(child: child),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const light = Color(0xFFF3F3F3);
    const dark = Color(0xFFE4E4E4);
    const tile = 12.0;

    final lightPaint = Paint()..color = light;
    final darkPaint = Paint()..color = dark;

    canvas.drawRect(Offset.zero & size, lightPaint);

    for (var row = 0; row * tile < size.height; row += 1) {
      for (var col = 0; col * tile < size.width; col += 1) {
        if ((row + col).isOdd) {
          canvas.drawRect(
            Rect.fromLTWH(col * tile, row * tile, tile, tile),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
