import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../state/card_provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/products_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../widgets/app_image.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;

  int _currentImage = 0;
  String? _selectedSize;
  int _selectedColorIndex = 0;
  bool _descExpanded = false;
  PageController _pageController = PageController();

  int get _imagesPerColor {
    if (_product == null || _product!.colors.isEmpty) return 1;
    return (_product!.images.length / _product!.colors.length).floor();
  }

  List<String> get _currentColorImages {
    if (_product == null) return [];
    final start = _selectedColorIndex * _imagesPerColor;
    final end = (start + _imagesPerColor).clamp(0, _product!.images.length);
    return _product!.images.sublist(start, end);
  }

  void _selectColor(int i) {
    _pageController.dispose();
    _pageController = PageController();
    setState(() {
      _selectedColorIndex = i;
      _currentImage = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final raw = await rootBundle.loadString('assets/mock/products.json');
    final list = (jsonDecode(raw) as List).map((e) => Product.fromJson(e)).toList();
    final product = list.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => list.first,
    );
    setState(() {
      _product = product;
      _loading = false;
    });
  }

  void _addToCart() {
    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a size',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.white)),
          backgroundColor: AppColors.grey800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
      return;
    }
    final p = _product!;
    ref.read(cartProvider.notifier).add(
          p,
          _selectedSize!,
          p.colors[_selectedColorIndex].name,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to bag',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.black)),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const ShimmerProductDetail(),
      );
    }

    final p = _product!;

    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isTablet
          ? _buildTabletLayout(p)
          : Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildImageGallery(p),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(p),
                        const SizedBox(height: 20),
                        _buildColorSelector(p),
                        const SizedBox(height: 20),
                        _buildSizeSelector(p),
                        const SizedBox(height: 20),
                        _buildDescription(p),
                        const SizedBox(height: 24),
                        _buildReviewSummary(p),
                        const SizedBox(height: 32),
                        _buildYouMayAlsoLike(p),
                      ],
                    ),
                  ),
              ),
            ],
          ),
          // Overlay top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildOverlayBar(p),
          ),
          // Bottom CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCTA(p),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(Product p) {
    final images = _currentColorImages;
    return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: gallery with thumbnails
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _currentImage = i),
                        itemBuilder: (_, i) => i == 0
                            ? Hero(
                                tag: 'product-image-${p.id}',
                                child: SizedBox.expand(
                                  child: AppImage(url: images[i], fit: BoxFit.cover),
                                ),
                              )
                            : SizedBox.expand(
                                child: AppImage(url: images[i], fit: BoxFit.cover),
                              ),
                      ),
                      Positioned(
                        top: 0, left: 0, right: 0,
                        child: _buildOverlayBar(p),
                      ),
                    ],
                  ),
                ),
                if (images.length > 1)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _currentImage == i
                                  ? AppColors.accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: AppImage(url: images[i], fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Right: details locked to same height
          Expanded(
            flex: 5,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(p),
                          const SizedBox(height: 20),
                          _buildColorSelector(p),
                          const SizedBox(height: 20),
                          _buildSizeSelector(p),
                          const SizedBox(height: 20),
                          const SizedBox(height: 24),
                          _buildDescription(p),
                          const SizedBox(height: 24),
                          _buildReviewSummary(p),
                          const SizedBox(height: 32),
                          _buildYouMayAlsoLike(p),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomCTA(p),
                ],
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildOverlayBar(Product p) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _CircleButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
              const Spacer(),
              _CircleButton(
                icon: ref.watch(favoritesProvider).contains(_product?.id ?? '')
                    ? Icons.favorite
                    : Icons.favorite_border,
                iconColor: ref.watch(favoritesProvider).contains(_product?.id ?? '')
                    ? AppColors.error
                    : AppColors.white,
                onTap: () => ref.read(favoritesProvider.notifier).toggle(_product!.id),
              ),
              const SizedBox(width: 8),
              _CircleButton(
                icon: Icons.share_outlined,
                onTap: () {},
              ),
            ],
          ),
        ),
      );

  Widget _buildImageGallery(Product p) {
    final images = _currentColorImages;
    if (images.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.52,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentImage = i),
              itemBuilder: (_, i) => i == 0
                  ? Hero(
                      tag: 'product-image-${p.id}',
                      child: SizedBox.expand(
                        child: AppImage(url: images[i], fit: BoxFit.cover),
                      ),
                    )
                  : SizedBox.expand(
                      child: AppImage(url: images[i], fit: BoxFit.cover),
                    ),
            ),
          ),
          // Thumbnail strip
          if (images.length > 1)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentImage == i
                            ? AppColors.accent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: AppImage(url: images[i], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Product p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.isNew)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        color: AppColors.accent,
                        child: Text('NEW ARRIVAL',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.black, fontSize: 9)),
                      ),
                    Text(p.name,
                        style: AppTextStyles.h2.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(p.brand.toUpperCase(),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.grey500)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${p.price.toStringAsFixed(0)}',
                      style: AppTextStyles.price),
                  if (p.hasDiscount)
                    Text('\$${p.originalPrice!.toStringAsFixed(0)}',
                        style: AppTextStyles.priceStrike),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < p.rating.floor() ? Icons.star : Icons.star_border,
                  color: AppColors.accent,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text('${p.rating}',
                  style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              Text(' (${p.reviewCount} reviews)',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500)),
            ],
          ),
        ],
      );

  Widget _buildColorSelector(Product p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('COLOR',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400)),
              const SizedBox(width: 8),
              Text(p.colors[_selectedColorIndex].name,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              p.colors.length,
              (i) {
                final c = p.colors[i];
                final selected = i == _selectedColorIndex;
                return GestureDetector(
                  onTap: () => _selectColor(i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(c.hex),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.grey700,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: selected
                        ? Center(
                            child: Icon(Icons.check,
                                size: 14,
                                color: Color(c.hex).computeLuminance() > 0.5
                                    ? AppColors.black
                                    : AppColors.white))
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _buildSizeSelector(Product p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SIZE',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.sizes.map((size) {
              final selected = size == _selectedSize;
              return GestureDetector(
                onTap: () => setState(() => _selectedSize = size),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                    border: Border.all(
                      color: selected ? Theme.of(context).colorScheme.onSurface : AppColors.grey700,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    size,
                    style: AppTextStyles.labelMedium.copyWith(
                      color:
                          selected ? AppColors.black : AppColors.grey400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildDescription(Product p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.grey800),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Row(
              children: [
                Text('DESCRIPTION',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                const Spacer(),
                Icon(
                  _descExpanded ? Icons.remove : Icons.add,
                  color: AppColors.grey400,
                  size: 16,
                ),
              ],
            ),
          ),
          if (_descExpanded) ...[
            const SizedBox(height: 12),
            Text(p.description,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75), height: 1.7)),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.grey800),
        ],
      );

  Widget _buildReviewSummary(Product p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('REVIEWS',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    context.push('/reviews/${p.id}'),
                child: Text('SEE ALL',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(p.rating.toString(),
                  style: AppTextStyles.h1.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < p.rating.floor()
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.accent,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${p.reviewCount} reviews',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500)),
                ],
              ),
            ],
          ),
          ],
        );

  Widget _buildYouMayAlsoLike(Product p) {
    final allProducts = ref.watch(productsProvider).valueOrNull ?? [];
    if (allProducts.isEmpty) return const SizedBox.shrink();

    final suggestions = allProducts
        .where((x) => x.id != p.id)
        .take(6)
        .toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOU MAY ALSO LIKE',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            padding: const EdgeInsets.only(left: 0),
            itemBuilder: (_, i) {
              final prod = suggestions[i];
              return GestureDetector(
                onTap: () => context.push('/product/${prod.id}'),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 154,
                        child: AppImage(url: prod.images.first, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 6),
                      Text(prod.brand.toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.grey500, fontSize: 8)),
                      const SizedBox(height: 2),
                      Text(prod.name,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('\$${prod.price.toStringAsFixed(0)}',
                          style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.accent)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA(Product p) {
    final c = ref.watch(cartItemCountProvider);
    return Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: const Border(
              top: BorderSide(color: AppColors.grey800, width: 1)),
        ),
        child: Row(
          children: [
            // Cart icon
            GestureDetector(
              onTap: () => context.push('/cart'),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20),
                    if (c > 0)
                      Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            c > 9 ? '9+' : '$c',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.black,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Add to cart button
            Expanded(
              child: GestureDetector(
                onTap: _addToCart,
                child: Container(
                  height: 52,
                  color: AppColors.accent,
                  alignment: Alignment.center,
                  child: Text(
                    _selectedSize == null
                        ? 'SELECT SIZE'
                        : 'ADD TO CART — \$${p.price.toStringAsFixed(0)}',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}

// Reusable widgets

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _CircleButton(
      {required this.icon, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppColors.white, size: 20),
        ),
      );
}
