import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class AppImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  bool get _isAsset => url.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback;
    if (_isAsset) {
      if (kIsWeb) {
        final absoluteUrl = Uri.base.resolve(url).toString();
        // Explicit finite dimensions: wrap in SizedBox so web renders at correct size.
        if (width != null && height != null &&
            width!.isFinite && height!.isFinite) {
          return SizedBox(
            width: width,
            height: height,
            child: Image.network(
              absoluteUrl,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (_, __, ___) => _fallback,
            ),
          );
        }
        // No explicit size — fill parent via SizedBox.expand.
        return SizedBox.expand(
          child: Image.network(
            absoluteUrl,
            fit: fit,
            errorBuilder: (_, __, ___) => _fallback,
          ),
        );
      }
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.grey200,
        highlightColor: AppColors.grey100,
        child: Container(color: AppColors.grey200),
      ),
      errorWidget: (_, __, ___) => _fallback,
    );
  }

  Widget get _fallback => Container(
        color: AppColors.grey900,
        child: const Icon(Icons.image_not_supported,
            color: AppColors.grey700, size: 32),
      );
}
