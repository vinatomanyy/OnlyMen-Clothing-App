import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../state/favorites_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive.dart';
import '../../widgets/shimmer_widgets.dart';

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
  Set<String> _selectedSizes = {};
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
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

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    if (_minPrice != null) {
      result = result.where((p) => p.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      result = result.where((p) => p.price <= _maxPrice!).toList();
    }

    if (_selectedSizes.isNotEmpty) {
      result = result.where((p) => p.sizes.any((s) => _selectedSizes.contains(s))).toList();
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

  Widget _buildSizeRow(List<String> sizes, StateSetter setSheetState) => Row(
        children: sizes.map((size) {
          final selected = _selectedSizes.contains(size);
          return GestureDetector(
            onTap: () {
              setSheetState(() {
                selected ? _selectedSizes.remove(size) : _selectedSizes.add(size);
              });
              setState(() {});
              _applyFilters();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.white : Colors.transparent,
                border: Border.all(color: selected ? AppColors.white : AppColors.grey600),
              ),
              child: Text(
                size,
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected ? AppColors.black : AppColors.white,
                ),
              ),
            ),
          );
        }).toList(),
      );

  void _showFilterSheet() {
    const numericSizes = ['40', '41', '42', '43', '44', '45'];
    const letterSizes = ['S', 'M', 'L', 'XL', 'One Size'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('FILTER', style: AppTextStyles.labelLarge.copyWith(color: AppColors.white)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSizes = {};
                        _searchQuery = '';
                        _minPrice = null;
                        _maxPrice = null;
                        _searchController.clear();
                        _minPriceController.clear();
                        _maxPriceController.clear();
                      });
                      _applyFilters();
                      Navigator.pop(ctx);
                    },
                    child: Text('CLEAR ALL', style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                onChanged: (val) {
                  setSheetState(() => _searchQuery = val);
                  setState(() {});
                  _applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                  prefixIcon: const Icon(Icons.search, color: AppColors.grey500, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            setSheetState(() => _searchQuery = '');
                            _searchController.clear();
                            setState(() {});
                            _applyFilters();
                          },
                          child: const Icon(Icons.close, color: AppColors.grey500, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.grey900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.grey700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.grey700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Text('PRICE RANGE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                      onChanged: (val) {
                        setSheetState(() => _minPrice = double.tryParse(val));
                        setState(() {});
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Min',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                        prefixText: '\$ ',
                        prefixStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
                        filled: true,
                        fillColor: AppColors.grey900,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.grey700)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.grey700)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.accent)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('—', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                      onChanged: (val) {
                        setSheetState(() => _maxPrice = double.tryParse(val));
                        setState(() {});
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Max',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                        prefixText: '\$ ',
                        prefixStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
                        filled: true,
                        fillColor: AppColors.grey900,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.grey700)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.grey700)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.accent)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('SIZE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              _buildSizeRow(numericSizes, setSheetState),
              const SizedBox(height: 8),
              _buildSizeRow(letterSizes, setSheetState),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  color: AppColors.accent,
                  alignment: Alignment.center,
                  child: Text(
                    'APPLY (${_filtered.length} items)',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                _buildCategoryTabs(),
                _buildFilterBar(),
                Expanded(child: _loading ? const ShimmerProductGrid() : _buildGrid()),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    final fg = Theme.of(context).colorScheme.onSurface;
    return AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedCategory == 'All' ? 'ALL APPAREL' : _selectedCategory.toUpperCase(),
          style: AppTextStyles.labelLarge.copyWith(color: fg),
        ),
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.tune, color: fg),
                onPressed: _showFilterSheet,
              ),
              if (_selectedSizes.isNotEmpty || _searchQuery.isNotEmpty || _minPrice != null || _maxPrice != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
  }

  Widget _buildCategoryTabs() {
    final fg = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
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
                  color: selected ? fg : Colors.transparent,
                  border: Border.all(
                    color: selected ? fg : AppColors.grey700,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: selected ? Theme.of(context).scaffoldBackgroundColor : AppColors.grey400,
                  ),
                ),
              ),
            );
          },
        ),
      );
  }

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
                    style: AppTextStyles.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurface, size: 16),
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
      : LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context), 0,
                Responsive.horizontalPadding(context), 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.gridColumns(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.62,
            ),
            itemCount: _filtered.length,
            itemBuilder: (_, i) => _ProductCard(product: _filtered[i]),
          ),
        );
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final favorites = ref.watch(favoritesProvider);
    final isFavorited = favorites.contains(p.id);
    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                Hero(
                  tag: 'product-image-${p.id}',
                  child: Container(
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
                    onTap: () => ref.read(favoritesProvider.notifier).toggle(p.id),
                    child: Container(
                      width: 32,
                      height: 32,
                      color: AppColors.black.withValues(alpha: 0.5),
                      child: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? AppColors.error : AppColors.white,
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