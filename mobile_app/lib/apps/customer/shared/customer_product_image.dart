import 'package:flutter/material.dart';

class CustomerProductImage extends StatelessWidget {
  const CustomerProductImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.semanticLabel,
  });

  final String imageUrl;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Semantics(
        label: semanticLabel ?? '',
        child: _buildImage(context),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final url = imageUrl.trim();

    if (url.isEmpty) {
      return _fallback(context);
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _loadingPlaceholder(context);
      },
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  Widget _loadingPlaceholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 26,
          color: scheme.onSurface.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}
