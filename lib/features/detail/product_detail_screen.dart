import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  List<Product> _related = [];
  bool _loading = true;

  int _currentImage = 0;
  String? _selectedSize;
  int _selectedColorIndex = 0;
  FitFeedback? _fitFeedback;
  bool _favorited = false;
  bool _descExpanded = false;

  final PageController _pageController = PageController();

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
    final related = list
        .where((p) => p.category == product.category && p.id != product.id)
        .take(4)
        .toList();
    setState(() {
      _product = product;
      _related = related;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to cart',
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
      return const Scaffold(
        backgroundColor: AppColors.surfaceDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final p = _product!;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Stack(
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
                      _buildFitFeedback(),
                      const SizedBox(height: 24),
                      _buildDescription(p),
                      const SizedBox(height: 24),
                      _buildReviewSummary(p),
                      if (_related.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildCompleteTheLook(),
                      ],
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

  Widget _buildOverlayBar(Product p) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _CircleButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              _CircleButton(
                icon: _favorited ? Icons.favorite : Icons.favorite_border,
                iconColor: _favorited ? AppColors.error : AppColors.white,
                onTap: () => setState(() => _favorited = !_favorited),
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

  Widget _buildImageGallery(Product p) => SliverToBoxAdapter(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.58,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: p.images.length,
                onPageChanged: (i) => setState(() => _currentImage = i),
                itemBuilder: (_, i) => Image.network(
                  p.images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.grey900,
                    child: const Icon(Icons.image_not_supported,
                        color: AppColors.grey700, size: 48),
                  ),
                ),
              ),
              // Dot indicators
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    p.images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentImage == i ? 20 : 6,
                      height: 2,
                      color: _currentImage == i
                          ? AppColors.white
                          : AppColors.grey600,
                    ),
                  ),
                ),
              ),
              // Thumbnail strip
              if (p.images.length > 1)
                Positioned(
                  right: 12,
                  top: 80,
                  child: Column(
                    children: List.generate(
                      p.images.length,
                      (i) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          width: 44,
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _currentImage == i
                                  ? AppColors.accent
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Image.network(p.images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: AppColors.grey800)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

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
                        style:
                            AppTextStyles.h2.copyWith(color: AppColors.white)),
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
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.white)),
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
                      .copyWith(color: AppColors.white)),
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
                  onTap: () => setState(() => _selectedColorIndex = i),
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
          Row(
            children: [
              Text('SIZE',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400)),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text('SIZE GUIDE',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accent)),
              ),
            ],
          ),
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
                    color: selected ? AppColors.white : Colors.transparent,
                    border: Border.all(
                      color:
                          selected ? AppColors.white : AppColors.grey700,
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

  Widget _buildFitFeedback() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FIT FEEDBACK',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
          const SizedBox(height: 10),
          Row(
            children: [
              _FitChip(
                label: 'Runs Small',
                selected: _fitFeedback == FitFeedback.runsSmall,
                onTap: () => setState(() => _fitFeedback =
                    _fitFeedback == FitFeedback.runsSmall
                        ? null
                        : FitFeedback.runsSmall),
              ),
              const SizedBox(width: 8),
              _FitChip(
                label: 'True to Size',
                selected: _fitFeedback == FitFeedback.trueToSize,
                onTap: () => setState(() => _fitFeedback =
                    _fitFeedback == FitFeedback.trueToSize
                        ? null
                        : FitFeedback.trueToSize),
              ),
              const SizedBox(width: 8),
              _FitChip(
                label: 'Runs Large',
                selected: _fitFeedback == FitFeedback.runsLarge,
                onTap: () => setState(() => _fitFeedback =
                    _fitFeedback == FitFeedback.runsLarge
                        ? null
                        : FitFeedback.runsLarge),
              ),
            ],
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
                        .copyWith(color: AppColors.white)),
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
                    .copyWith(color: AppColors.grey300, height: 1.7)),
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
                      .copyWith(color: AppColors.white)),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/reviews', arguments: p.id),
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
                  style: AppTextStyles.h1.copyWith(color: AppColors.white)),
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

  Widget _buildCompleteTheLook() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMPLETE THE LOOK',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _related.length,
              itemBuilder: (_, i) {
                final r = _related[i];
                return GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(
                      context, '/detail',
                      arguments: r),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            r.images.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                Container(color: AppColors.grey800),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(r.name,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('\$${r.price.toStringAsFixed(0)}',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.accent)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _buildBottomCTA(Product p) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: const Border(
              top: BorderSide(color: AppColors.grey800, width: 1)),
        ),
        child: Row(
          children: [
            // Cart icon
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/cart'),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey700),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    color: AppColors.white, size: 20),
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
            color: AppColors.black.withOpacity(0.55),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppColors.white, size: 20),
        ),
      );
}

class _FitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FitChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.grey700,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected ? AppColors.black : AppColors.grey400,
              fontSize: 10,
            ),
          ),
        ),
      );
}