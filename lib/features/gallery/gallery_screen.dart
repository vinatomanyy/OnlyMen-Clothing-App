import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../models/promotion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/shimmer_widgets.dart';

class _MediaItem {
  final String imageUrl;
  final String title;
  final String tag;
  final bool isVideo;

  const _MediaItem({
    required this.imageUrl,
    required this.title,
    required this.tag,
    this.isVideo = false,
  });
}

const _mediaItems = [
  _MediaItem(
    imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800',
    title: 'The Architecture of Winter',
    tag: 'RUNWAY',
    isVideo: true,
  ),
  _MediaItem(
    imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=800',
    title: 'Smart Casual Redefined',
    tag: 'EDITORIAL',
  ),
  _MediaItem(
    imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800',
    title: 'The Modern Wardrobe',
    tag: 'LOOKBOOK',
    isVideo: true,
  ),
  _MediaItem(
    imageUrl: 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
    title: 'Weekend Warrior',
    tag: 'STYLE GUIDE',
  ),
  _MediaItem(
    imageUrl: 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800',
    title: 'Business Refined',
    tag: 'RUNWAY',
    isVideo: true,
  ),
  _MediaItem(
    imageUrl: 'https://images.unsplash.com/photo-1520975954732-35dd22299614?w=800',
    title: 'Editorial Series',
    tag: 'EDITORIAL',
  ),
  _MediaItem(
    imageUrl: 'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=800',
    title: 'Street Style',
    tag: 'STYLE GUIDE',
    isVideo: true,
  ),
  _MediaItem(
    imageUrl: 'https://images.unsplash.com/photo-1550246140-29f40b909e5a?w=800',
    title: 'Capsule Collection',
    tag: 'LOOKBOOK',
  ),
];

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Promotion> _promos = [];
  bool _loading = true;
  final Set<String> _copiedCodes = {};

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    final raw = await rootBundle.loadString('assets/mock/promotions.json');
    final promos = (jsonDecode(raw) as List).map((e) => Promotion.fromJson(e)).toList();
    setState(() {
      _promos = promos;
      _loading = false;
    });
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedCodes.add(code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Code $code copied!',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.black)),
      backgroundColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  void _openViewer(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullScreenViewer(
        items: _mediaItems,
        initialIndex: index,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('MEDIA',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.white, letterSpacing: 3)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.white),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: _loading
          ? const ShimmerMasonryGrid()
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Masonry grid
                MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _mediaItems.length,
                  itemBuilder: (_, i) => _GridTile(
                    item: _mediaItems[i],
                    index: i,
                    onTap: () => _openViewer(i),
                  ),
                ),
                const SizedBox(height: 24),
                // Promotions section
                if (_promos.isNotEmpty) ...[
                  Text('PROMOTIONS',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.grey400, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  ..._promos.map((p) => _PromoCard(
                        promo: p,
                        copied: _copiedCodes.contains(p.code),
                        onCopy: () => _copyCode(p.code),
                      )),
                ],
              ],
            ),
    );
  }
}

// ── Grid tile ─────────────────────────────────────────────────────
class _GridTile extends StatelessWidget {
  final _MediaItem item;
  final int index;
  final VoidCallback onTap;

  const _GridTile({required this.item, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Alternate heights for masonry effect
    final height = index % 3 == 0 ? 220.0 : index % 3 == 1 ? 160.0 : 190.0;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.grey900),
            ),
            // Gradient
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.black.withValues(alpha: 0.6)],
                ),
              ),
            ),
            // Tag
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: AppColors.accent,
                child: Text(item.tag,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.black, fontSize: 8, letterSpacing: 1)),
              ),
            ),
            // Play icon
            if (item.isVideo)
              Center(
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1),
                  ),
                  child: const Icon(Icons.play_arrow, color: AppColors.white, size: 18),
                ),
              ),
            // Title at bottom
            Positioned(
              bottom: 8, left: 8, right: 8,
              child: Text(item.title,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.white, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full screen viewer ────────────────────────────────────────────
class _FullScreenViewer extends StatefulWidget {
  final List<_MediaItem> items;
  final int initialIndex;

  const _FullScreenViewer({required this.items, required this.initialIndex});

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          children: [
            PhotoViewGallery.builder(
              itemCount: widget.items.length,
              pageController: PageController(initialPage: widget.initialIndex),
              onPageChanged: (i) => setState(() => _current = i),
              builder: (_, i) => PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(widget.items[i].imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              ),
              backgroundDecoration: const BoxDecoration(color: AppColors.black),
            ),
            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: AppColors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_current + 1} / ${widget.items.length}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom title
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: AppColors.accent,
                        child: Text(widget.items[_current].tag,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.black, fontSize: 9)),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.items[_current].title,
                          style: AppTextStyles.h3.copyWith(color: AppColors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Promo card ────────────────────────────────────────────────────
class _PromoCard extends StatelessWidget {
  final Promotion promo;
  final bool copied;
  final VoidCallback onCopy;

  const _PromoCard({required this.promo, required this.copied, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final daysLeft = promo.expiryDate.difference(DateTime.now()).inDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border.all(color: AppColors.grey800),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: AppColors.error,
                      child: Text('-${promo.discountPercent}% OFF',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.white, fontSize: 9)),
                    ),
                    const SizedBox(width: 8),
                    if (daysLeft <= 30)
                      Text('$daysLeft days left',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey500, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(promo.title,
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.white)),
                const SizedBox(height: 2),
                Text(promo.description,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: copied ? AppColors.accent : AppColors.grey600),
                color: copied ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Text(promo.code,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: copied ? AppColors.accent : AppColors.white,
                          letterSpacing: 1.5)),
                  const SizedBox(width: 6),
                  Icon(copied ? Icons.check : Icons.copy_outlined,
                      color: copied ? AppColors.accent : AppColors.grey500, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
