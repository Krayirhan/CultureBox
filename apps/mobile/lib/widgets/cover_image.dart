import 'package:flutter/material.dart';
import 'package:mobile/data/content_providers.dart';
import 'package:mobile/models/catalog.dart';
import 'package:mobile/theme/app_colors.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({super.key, required this.url, this.fallbackIcon});

  final String url;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: AppColors.card,
        child: Center(
          child: Icon(
            fallbackIcon ?? Icons.movie_filter_outlined,
            color: AppColors.muted,
            size: 28,
          ),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(color: AppColors.card);
      },
    );
  }
}

/// A [CoverImage] that silently swaps in a sharper poster for TV shows once
/// one is found. Reserved for single, high-visibility spots (a featured
/// card, a detail header) — looking one up per shelf item would multiply the
/// request count across the whole screen for a purely cosmetic upgrade.
class SharpCoverImage extends StatefulWidget {
  const SharpCoverImage({super.key, required this.item});

  final ContentItem item;

  @override
  State<SharpCoverImage> createState() => _SharpCoverImageState();
}

class _SharpCoverImageState extends State<SharpCoverImage> {
  late String _url = widget.item.imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.item.kind == 'Dizi') _upgrade();
  }

  @override
  void didUpdateWidget(covariant SharpCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.title != widget.item.title) {
      setState(() => _url = widget.item.imageUrl);
      if (widget.item.kind == 'Dizi') _upgrade();
    }
  }

  Future<void> _upgrade() async {
    final sharper = await const ContentProviders().higherResPoster(
      widget.item.title,
    );
    if (mounted && sharper != null) setState(() => _url = sharper);
  }

  @override
  Widget build(BuildContext context) => CoverImage(url: _url);
}
