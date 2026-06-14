import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/promotion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// Mock media feed items
class _FeedItem {
  final String type; // 'video' | 'promo' | 'editorial'
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? tag;
  final String? promoCode;
  final int? discountPercent;
  final String? actionLabel;
  final String? actionRoute;

  const _FeedItem({
    required this.type,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.tag,
    this.promoCode,
    this.discountPercent,
    this.actionLabel,
    this.actionRoute,
  });
}

const _mockFeed = [
  _FeedItem(
    type: 'video',
    imageUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800',
    title: 'The Architecture of Winter',
    subtitle: 'Runway SS26 — Milan Fashion Week',
    tag: 'RUNWAY',
    actionLabel: 'SHOP THE LOOK',
    actionRoute: '/lookbook',
  ),
  _FeedItem(
    type: 'editorial',
    imageUrl:
        'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=800',
    title: 'Smart Casual Redefined',
    subtitle:
        'How to dress effortlessly between the boardroom and the weekend.',
    tag: 'EDITORIAL',
    actionLabel: 'READ MORE',
    actionRoute: '/lookbook',
  ),
  _FeedItem(
    type: 'video',
    imageUrl:
        'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800',
    title: 'The Modern Wardrobe',
    subtitle: 'Capsule collection — 10 pieces, infinite outfits.',
    tag: 'LOOKBOOK',
    actionLabel: 'EXPLORE',
    actionRoute: '/lookbook',
  ),
  _FeedItem(
    type: 'editorial',
    imageUrl:
        'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
    title: 'Weekend Warrior',
    subtitle: 'Off-duty looks for the discerning man.',
    tag: 'STYLE GUIDE',
    actionLabel: 'SHOP NOW',
    actionRoute: '/category/all',
  ),
  _FeedItem(
    type: 'video',
    imageUrl:
        'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800',
    title: 'Business Refined',
    subtitle: 'Power dressing without the clichés.',
    tag: 'RUNWAY',
    actionLabel: 'SHOP THE LOOK',
    actionRoute: '/category/jackets',
  ),
];

class PromotionsScreen extends ConsumerlessPromotionsFeed {
  const PromotionsScreen({super.key});
}

// Base class so PromotionsScreen can reuse
class ConsumerlessPromotionsFeed extends StatefulWidget {
  const ConsumerlessPromotionsFeed({super.key});

  @override
  State<ConsumerlessPromotionsFeed> createState() => _MediaFeedState();
}

class _MediaFeedState extends State<ConsumerlessPromotionsFeed> {
  List<Promotion> _promotions = [];
  bool _loading = true;
  final Set<String> _copiedCodes = {};

  // Interleave feed: editorial item, then promo every 3 items
  List<dynamic> _feedItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final raw =
        await rootBundle.loadString('assets/mock/promotions.json');
    final promos = (jsonDecode(raw) as List)
        .map((e) => Promotion.fromJson(e))
        .toList();

    // Interleave: 2 feed items, 1 promo, repeat
    final List<dynamic> combined = [];
    int promoIdx = 0;
    for (int i = 0; i < _mockFeed.length; i++) {
      combined.add(_mockFeed[i]);
      if ((i + 1) % 2 == 0 && promoIdx < promos.length) {
        combined.add(promos[promoIdx++]);
      }
    }
    // Add remaining promos
    while (promoIdx < promos.length) {
      combined.add(promos[promoIdx++]);
    }

    setState(() {
      _promotions = promos;
      _feedItems = combined;
      _loading = false;
    });
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedCodes.add(code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $code copied!',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.black)),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accent))
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final item = _feedItems[i];
                      if (item is _FeedItem) {
                        return _FeedCard(item: item);
                      } else if (item is Promotion) {
                        return _PromoCard(
                          promo: item,
                          copied: _copiedCodes.contains(item.code),
                          onCopy: () => _copyCode(item.code),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: _feedItems.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  SliverAppBar _buildAppBar() => SliverAppBar(
        backgroundColor: AppColors.black,
        floating: true,
        snap: true,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'MEDIA',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.white,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.white),
            onPressed: () => context.push('/search'),
          ),
        ],
      );
}

// ── Feed card (video / editorial) ────────────────────────────────
class _FeedCard extends StatefulWidget {
  final _FeedItem item;
  const _FeedCard({required this.item});

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _liked = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.75,
      margin: const EdgeInsets.only(bottom: 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (simulates video frame)
          Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: AppColors.grey900),
          ),

          // Gradient overlays
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.2, 0.5, 1.0],
              ),
            ),
          ),

          // Top tag
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              color: AppColors.accent,
              child: Text(
                item.tag ?? '',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.black,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // Play icon for video type
          if (item.type == 'video')
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.white, width: 1.5),
                ),
                child: const Icon(Icons.play_arrow,
                    color: AppColors.white, size: 28),
              ),
            ),

          // Right side actions
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                _SideAction(
                  icon: _liked ? Icons.favorite : Icons.favorite_border,
                  iconColor: _liked ? AppColors.error : AppColors.white,
                  label: _liked ? 'Saved' : 'Like',
                  onTap: () => setState(() => _liked = !_liked),
                ),
                const SizedBox(height: 20),
                _SideAction(
                  icon: _saved
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  iconColor:
                      _saved ? AppColors.accent : AppColors.white,
                  label: 'Save',
                  onTap: () => setState(() => _saved = !_saved),
                ),
                const SizedBox(height: 20),
                _SideAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Bottom content
          Positioned(
            bottom: 0,
            left: 0,
            right: 72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.white,
                      fontSize: 22,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey300),
                      maxLines: 2,
                    ),
                  ],
                  if (item.actionLabel != null &&
                      item.actionRoute != null) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => context.push(item.actionRoute!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.actionLabel!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward,
                              color: AppColors.accent, size: 12),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Promo card ────────────────────────────────────────────────────
class _PromoCard extends StatelessWidget {
  final Promotion promo;
  final bool copied;
  final VoidCallback onCopy;

  const _PromoCard({
    required this.promo,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = promo.expiryDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          if (promo.imageUrl != null)
            Image.network(
              promo.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.grey900),
            )
          else
            Container(color: AppColors.grey900),

          // Dark overlay
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.72),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      color: AppColors.error,
                      child: Text(
                        '-${promo.discountPercent}% OFF',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (daysLeft <= 30)
                      Text(
                        '$daysLeft days left',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey400, fontSize: 11),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  promo.title,
                  style:
                      AppTextStyles.h3.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  promo.description,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey400),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Promo code copy
                GestureDetector(
                  onTap: onCopy,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: copied
                                ? AppColors.accent
                                : AppColors.grey600,
                          ),
                          color: copied
                              ? AppColors.accent.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Text(
                              promo.code,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: copied
                                    ? AppColors.accent
                                    : AppColors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              copied
                                  ? Icons.check
                                  : Icons.copy_outlined,
                              color: copied
                                  ? AppColors.accent
                                  : AppColors.grey500,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Side action button ────────────────────────────────────────────
class _SideAction extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  const _SideAction({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? AppColors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.white, fontSize: 10),
            ),
          ],
        ),
      );
}

