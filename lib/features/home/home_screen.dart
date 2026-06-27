import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/app_image.dart';
import '../../models/product.dart';
import '../../state/products_provider.dart';
import '../../state/promotions_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/theme_provider.dart';
import '../../utils/responsive.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      body: CustomScrollView(
        slivers: [
          _AppBar(),
          const SliverToBoxAdapter(child: _PromotionsStrip()),
          const SliverToBoxAdapter(child: _HeroSection()),
          const SliverToBoxAdapter(child: _BestsellersSection()),
          const SliverToBoxAdapter(child: _NewArrivalsSection()),
          const SliverToBoxAdapter(child: _CategoriesSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────
class _AppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final fg = isDark ? AppColors.white : AppColors.black;
    final bg = isDark ? AppColors.surfaceDark : AppColors.white;

    return SliverAppBar(
      floating: true,
      backgroundColor: bg,
      elevation: 0,
      leading: Tooltip(
        message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
        child: IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: fg,
          ),
          onPressed: () => ref.read(themeProvider.notifier).toggle(),
        ),
      ),
      title: Text(
        'OnlyMen',
        style: AppTextStyles.h2.copyWith(color: fg, letterSpacing: 2),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.map_outlined, color: fg),
          onPressed: () => context.push('/map'),
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
      'image': 'assets/images/home1.jpg',
      'tag': 'EDITORIAL FEATURE',
      'title': 'Architecture of\nYour Own Style.',
      'cta': 'Shop the Look',
      'category': 'jackets',
    },
    {
      'image': 'assets/images/home2.jpg',
      'tag': 'NEW COLLECTION',
      'title': 'Breeze of\nthe Summer.',
      'cta': 'Explore Now',
      'category': 'shirts',
    },
    {
      'image': 'assets/images/home3.jpg',
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
                  AppImage(url: slide['image']!, fit: BoxFit.cover),
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
class _PromotionsStrip extends ConsumerWidget {
  const _PromotionsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotions = ref.watch(promotionsProvider);
    return promotions.when(
      data: (promos) {
        if (promos.isEmpty) return const SizedBox.shrink();
        final promo = promos.first;
        return GestureDetector(
          onTap: () => context.push('/promotions'),
          child: Container(
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
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.white, size: 12),
              ],
            ),
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

// ── Bestsellers ───────────────────────────────────────────────
class _BestsellersSection extends ConsumerWidget {
  const _BestsellersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(bestsellersProvider);
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
                const Text('Best Sellers', style: AppTextStyles.h3),
                GestureDetector(
                  onTap: () => context.push('/category/all'),
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
              data: (items) {
                const columns = 3;
                final capped = items.take(columns).toList();
                if (capped.isEmpty) return const _EmptyProducts();
                return LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 8.0;
                    const hPad = 20.0;
                    final cardWidth =
                        (constraints.maxWidth - hPad * 2 - gap * (columns - 1)) /
                        columns;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: hPad),
                      child: Row(
                        children: List.generate(capped.length, (i) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ProductCard(product: capped[i], width: cardWidth),
                            if (i < capped.length - 1)
                              const SizedBox(width: gap),
                          ],
                        )),
                      ),
                    );
                  },
                );
              },
              loading: () => const _ShimmerProductList(),
              error: (_, __) => const _EmptyProducts(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── New Arrivals ──────────────────────────────────────────────
class _NewArrivalsSection extends ConsumerWidget {
  const _NewArrivalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onTap: () => context.push('/category/all'),
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
              data: (items) {
                const columns = 3;
                final capped = items.take(columns).toList();
                if (capped.isEmpty) return const _EmptyProducts();
                return LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 8.0;
                    const hPad = 20.0;
                    final cardWidth =
                        (constraints.maxWidth - hPad * 2 - gap * (columns - 1)) /
                        columns;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: hPad),
                      child: Row(
                        children: List.generate(capped.length, (i) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ProductCard(product: capped[i], width: cardWidth),
                            if (i < capped.length - 1)
                              const SizedBox(width: gap),
                          ],
                        )),
                      ),
                    );
                  },
                );
              },
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
  final double? width;
  const _ProductCard({required this.product, this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'product-image-${product.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox.expand(
                        child: AppImage(
                          url: product.images.isNotEmpty
                              ? product.images.first
                              : '',
                          fit: BoxFit.cover,
                        ),
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

  static const _categories = [
    {'label': 'Shirts',      'value': 'shirts',      'icon': Icons.checkroom_outlined},
    {'label': 'Jackets',     'value': 'jackets',     'icon': Icons.layers_outlined},
    {'label': 'Footwear',    'value': 'shoes',       'icon': Icons.hiking_outlined},
    {'label': 'Accessories', 'value': 'accessories', 'icon': Icons.watch_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context),
            32,
            Responsive.horizontalPadding(context),
            16,
          ),
          child: const Text('Explore by Category', style: AppTextStyles.h3),
        ),
        SizedBox(
          height: 110,
          child: Row(
            children: _categories.map((cat) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/category/${cat['value']}'),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 26,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['label'] as String,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
