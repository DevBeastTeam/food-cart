import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData fallbackIcon;

  const CustomImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.fallbackIcon = Icons.fastfood_rounded,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imageUrl.isEmpty) {
      content = _buildPlaceholder();
    } else {
      content = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppTheme.surfaceMuted,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF3E8FF),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: (width != null && width! < 60) ? 20 : 36,
          color: AppTheme.primary.withAlpha(160),
        ),
      ),
    );
  }
}
