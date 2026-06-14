import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Product> _all = [];
  List<Product> _filtered = [];
  String _selectedCategory = 'All';
  String _sortBy = 'Featured';
  bool _loading = true;

  final List<String> _categories = [
    'All', 'Shirts', 'T-Shirts', 'Pants', 'Jackets', 'Shoes', 'Accessories'
  ];

  final List<String> _sortOptions = [
    'Featured', 'Price: Low to High', 'Price: High to Low', 'Newest', 'Top Rated'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category == 'all' ? 'All' : _capitalize(widget.category);
    _loadProducts();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _loadProducts() async {
    final raw = await rootBundle.loadString('assets/mock/products.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Product.fromJson(e))
        .toList();
    setState(() {
      _all = list;
      _loading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Product> result = List.from(_all);

    if (_selectedCategory != 'All') {
      final cat = _selectedCategory.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      result = result.where((p) {
        final pc = p.category.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
        // map display names to json category values
        if (cat == 'tshirts') return pc == 'tshirts';
        if (cat == 'shirts') return pc == 'shirts';
        if (cat == 'pants') return pc == 'pants';
        if (cat == 'jackets') return pc == 'jackets';
        if (cat == 'shoes') return pc == 'shoes';
        if (cat == 'accessories') return pc == 'accessories';
        return pc == cat;
      }).toList();
    }

    switch (_sortBy) {
      case 'Price: Low to High':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Newest':
        result = result.where((p) => p.isNew).toList()
          + result.where((p) => !p.isNew).toList();
        break;
      case 'Top Rated':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    setState(() => _filtered = result);
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('SORT BY',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400)),
            ),
            const SizedBox(height: 12),
            ..._sortOptions.map((opt) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(opt,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.white)),
                  trailing: _sortBy == opt
                      ? const Icon(Icons.check, color: AppColors.accent, size: 18)
                      : null,
                  onTap: () {
                    setState(() => _sortBy = opt);
                    _applyFilters();
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                _buildCategoryTabs(),
                _buildFilterBar(),
                Expanded(child: _buildGrid()),
              ],
            ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedCategory == 'All' ? 'ALL APPAREL' : _selectedCategory.toUpperCase(),
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.white),
            onPressed: () {},
          ),
        ],
      );

  Widget _buildCategoryTabs() => SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final selected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                _applyFilters();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.white : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.white : AppColors.grey700,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: selected ? AppColors.black : AppColors.grey400,
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildFilterBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              '${_filtered.length} ITEMS',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showSortSheet,
              child: Row(
                children: [
                  Text(
                    'SORT',
                    style:
                        AppTextStyles.labelSmall.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more,
                      color: AppColors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildGrid() => _filtered.isEmpty
      ? Center(
          child: Text('No items found',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500)),
        )
      : GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.62,
          ),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _ProductCard(product: _filtered[i]),
        );
}

class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _favorited = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.grey900,
                  child: Image.network(
                    p.images.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.grey800,
                      child: const Icon(Icons.image_not_supported,
                          color: AppColors.grey600),
                    ),
                  ),
                ),
                // Badges
                Positioned(
                  top: 8,
                  left: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.isNew)
                        _Badge(label: 'NEW', bg: AppColors.accent, fg: AppColors.black),
                      if (p.hasDiscount) ...[
                        const SizedBox(height: 4),
                        _Badge(label: '-${p.discountPercent}%', bg: AppColors.error, fg: AppColors.white),
                      ],
                    ],
                  ),
                ),
                // Favorite
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _favorited = !_favorited),
                    child: Container(
                      width: 32,
                      height: 32,
                      color: AppColors.black.withOpacity(0.5),
                      child: Icon(
                        _favorited ? Icons.favorite : Icons.favorite_border,
                        color: _favorited ? AppColors.error : AppColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            p.name,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Price row
          Row(
            children: [
              Text(
                '\$${p.price.toStringAsFixed(0)}',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.accent),
              ),
              if (p.hasDiscount) ...[
                const SizedBox(width: 6),
                Text(
                  '\$${p.originalPrice!.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Rating
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.accent, size: 10),
              const SizedBox(width: 3),
              Text(
                '${p.rating}',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.grey400),
              ),
              Text(
                ' (${p.reviewCount})',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: bg,
        child: Text(label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontSize: 9,
              letterSpacing: 0.8,
            )),
      );
}