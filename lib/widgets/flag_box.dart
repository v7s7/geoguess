import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FlagBox extends StatelessWidget {
  final String url;
  final double height;

  const FlagBox({super.key, required this.url, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
      ),
    );
  }
}