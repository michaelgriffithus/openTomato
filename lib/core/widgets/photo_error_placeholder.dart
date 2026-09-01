import 'package:flutter/material.dart';

class PhotoErrorPlaceholder extends StatelessWidget {
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;

  const PhotoErrorPlaceholder({
    super.key,
    this.size = 40,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor =
        iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: size,
          color: resolvedIconColor,
        ),
      ),
    );
  }
}
