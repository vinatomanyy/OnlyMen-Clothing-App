import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../state/favorites_provider.dart';
import '../../state/card_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<Product> _allProducts = [];
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final raw = await rootBundle.loadString('assets/mock/products.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Product.fromJson(e))
        .toList();
    setState(() {
      _allProducts = list;
      _loadingProducts = false;
    });
  }

  List<Product> _favoriteProducts(List<String> ids) =>
      _allProducts.where((p) => ids.contains(p.id)).toList();

  void _addToCart(BuildContext context, Product p) {
    ref.read(cartProvider.notifier).add(p, p.sizes.first, p.colors.first.name);
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
    final favoriteIds = ref.watch(favoritesProvider);
    final favorites = _favoriteProducts(favoriteIds);

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: _buildAppBar(context, favorites.length),
      body: _loadingProducts
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : favorites.isEmpty
              ? _buildEmptyState(context)
              : _buildGrid(context, favorites),
    );
  }

  AppBar _buildAppBar(BuildContext context, int count) => AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'SAVED',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.white),
            ),
            if (count > 0)
              Text(
                '$count ${count == 1 ? 'item' : 'items'}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey500, fontSize: 11),
              ),
          ],
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                color: AppColors.grey700, size: 64),
            const SizedBox(height: 16),
            Text('NOTHING SAVED YET',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.grey500)),
            const SizedBox(height: 8),
            Text('Tap ♡ on any item to save it here',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey700)),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                color: AppColors.white,
                child: Text('EXPLORE',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.black)),
              ),
            ),
          ],
        ),
      );

  Widget _buildGrid(BuildContext context, List<Product> favorites) =>
      GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.58,
        ),
        itemCount: favorites.length,
        itemBuilder: (_, i) => _FavoriteCard(
          product: favorites[i],
          onRemove: () =>
              ref.read(favoritesProvider.notifier).toggle(favorites[i].id),
          onAddToCart: () => _addToCart(context, favorites[i]),
        ),
      );
}

class _FavoriteCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  const _FavoriteCard({
    required this.product,
    required this.onRemove,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  p.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.grey800),
                ),
                // Remove favorite
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 32,
                      height: 32,
                      color: AppColors.black.withOpacity(0.55),
                      child: const Icon(Icons.favorite,
                          color: AppColors.error, size: 16),
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
                        _Badge(
                            label: 'NEW',
                            bg: AppColors.accent,
                            fg: AppColors.black),
                      if (p.hasDiscount) ...[
                        const SizedBox(height: 4),
                        _Badge(
                            label: '-${p.discountPercent}%',
                            bg: AppColors.error,
                            fg: AppColors.white),
                      ],
                    ],
                  ),
                ),
                // Add to bag overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onAddToCart,
                    child: Container(
                      height: 36,
                      color: AppColors.black.withOpacity(0.75),
                      alignment: Alignment.center,
                      child: Text(
                        'ADD TO BAG',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
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
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Price
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
                    color: AppColors.grey600,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Colors preview
          Row(
            children: p.colors.take(3).map((c) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Color(c.hex),
                  border: Border.all(
                      color: AppColors.grey700, width: 0.5),
                  shape: BoxShape.circle,
                ),
              );
            }).toList(),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: bg,
        child: Text(label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontSize: 9,
              letterSpacing: 0.8,
            )),
      );
}