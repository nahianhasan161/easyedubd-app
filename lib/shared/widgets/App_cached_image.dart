import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppCachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const AppCachedImage({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
    );
  }
}
