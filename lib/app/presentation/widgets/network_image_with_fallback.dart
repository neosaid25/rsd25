import 'package:flutter/material.dart';

class NetworkImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // التحقق من وجود URL صالح
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    return Image.network(
      imageUrl!,
      fit: fit,
      width: width,
      height: height,
      headers: const {'Accept': 'image/*'},
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
    );
  }

  Widget _buildPlaceholder(ImageChunkEvent? loadingProgress) {
    return placeholder ??
        Center(
          child: CircularProgressIndicator(
            value: loadingProgress?.expectedTotalBytes != null
                ? loadingProgress!.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          ),
        );
  }
}