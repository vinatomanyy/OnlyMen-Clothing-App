import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/product.dart';
import '../../state/products_provider.dart';
import '../../state/promotions_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          _AppBar(),
          const SliverToBoxAdapter(child: _HeroSection()),
          SliverToBoxAdapter(child: _PromotionsStrip(ref: ref)),
          SliverToBoxAdapter(child: _NewArrivalsSection(ref: ref)),
          const SliverToBoxAdapter(child: _CategoriesSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.black),
        onPressed: () {},
      ),
      title: Text(
        'OnlyMen',
        style: AppTextStyles.h2.copyWith(
          color: AppColors.black,
          letterSpacing: 2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.black),
          onPressed: () => context.push('/cart'),
        ),
      ],
    );
  }
}

// ── Hero Section ─────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  const _HeroSection();

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<Map<String, String>> _slides = [
    {
      'image':
          'https://images.unsplash.com/photo-1520975954732-35dd22299614?w=800',
      'tag': 'EDITORIAL FEATURE',
      'title': 'The Architecture\nof Winter',
      'cta': 'Shop the Look',
      'category': 'jackets',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800',
      'tag': 'NEW COLLECTION',
      'title': 'Sharp Minds,\nSharp Suits',
      'cta': 'Explore Now',
      'category': 'shirts',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=800',
      'tag': 'LOOKBOOK 2026',
      'title': 'Minimal.\nTimeless.',
      'cta': 'View Lookbook',
      'category': 'tshirts',
    },
  ];

  @override
  void initState() {
    super.initState();
    _autoPlay();
  }

  void _autoPlay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_current + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      _autoPlay();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 480,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: slide['image']!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.grey200,
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: AppColors.accent,
                          child: Text(
                            slide['tag']!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.black,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide['title']!,
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () =>
                              context.push('/category/${slide['category']}'),
                          child: Row(
                            children: [
                              Text(
                                slide['cta']!,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: AppColors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 16,
            right: 20,
            child: Row(
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(left: 4),
                  width: _current == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i ? AppColors.accent : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Promotions Strip ─────────────────────────────────────────
class _PromotionsStrip extends StatelessWidget {
  final WidgetRef ref;
  const _PromotionsStrip({required this.ref});

  @override
  Widget build(BuildContext context) {
    final promotions = ref.watch(promotionsProvider);
    return promotions.when(
      data: (promos) {
        if (promos.isEmpty) return const SizedBox.shrink();
        final promo = promos.first;
        return Container(
          color: AppColors.black,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined,
                  color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${promo.title} — Use code ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                color: AppColors.accent,
                child: Text(
                  promo.code,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.black,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/promotions'),
                child: const Icon(Icons.arrow_forward_ios,
                    color: AppColors.white, size: 12),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        color: AppColors.black,
        height: 40,
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── New Arrivals ──────────────────────────────────────────────
class _NewArrivalsSection extends StatelessWidget {
  final WidgetRef ref;
  const _NewArrivalsSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(newArrivalsProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Arrivals', style: AppTextStyles.h3),
                GestureDetector(
                  onTap: () => context.push('/category/new'),
                  child: Text(
                    'View All',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.grey500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: products.when(
              data: (items) => items.isEmpty
                  ? const _EmptyProducts()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _ProductCard(product: items[index]),
                    ),
              loading: () => const _ShimmerProductList(),
              error: (_, __) => const _EmptyProducts(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ─────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: CachedNetworkImage(
                      imageUrl: product.images.isNotEmpty
                          ? product.images.first
                          : '',
                      width: 180,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.grey200,
                        highlightColor: AppColors.grey100,
                        child: Container(color: AppColors.grey200),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.grey100,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.grey400),
                      ),
                    ),
                  ),
                  if (product.isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: AppColors.black,
                        child: Text(
                          'NEW',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 6),
                  Text(
                    '\$${product.originalPrice!.toStringAsFixed(0)}',
                    style: AppTextStyles.priceStrike.copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Categories Section ────────────────────────────────────────
class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context) {
    const categories = [
      {'label': 'Apparel', 'icon': Icons.checkroom_outlined, 'value': 'shirts'},
      {'label': 'Footwear', 'icon': Icons.accessibility_outlined, 'value': 'shoes'},
      {'label': 'Accessories', 'icon': Icons.watch_outlined, 'value': 'accessories'},
      {'label': 'Premium', 'icon': Icons.diamond_outlined, 'value': 'jackets'},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 32, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Explore Collection', style: AppTextStyles.h3),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories
                .map((cat) => _CategoryItem(
                      label: cat['label'] as String,
                      icon: cat['icon'] as IconData,
                      onTap: () => context.push('/category/${cat['value']}'),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, color: AppColors.black, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer Loading ───────────────────────────────────────────
class _ShimmerProductList extends StatelessWidget {
  const _ShimmerProductList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppColors.grey200,
        highlightColor: AppColors.grey100,
        child: Container(
          width: 180,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.grey300, size: 48),
          const SizedBox(height: 8),
          Text(
            'No products found',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}