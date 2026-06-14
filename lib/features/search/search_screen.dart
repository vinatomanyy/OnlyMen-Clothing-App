import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<Product> _allProducts = [];
  List<Product> _results = [];
  List<String> _recentSearches = ['Wool Overcoat', 'White Oxford', 'Chelsea Boots'];
  bool _loading = true;
  bool _hasQuery = false;

  final List<_CategoryShortcut> _shortcuts = const [
    _CategoryShortcut(label: 'Jackets', icon: Icons.checkroom_outlined, route: '/category/jackets'),
    _CategoryShortcut(label: 'Shirts', icon: Icons.dry_cleaning_outlined, route: '/category/shirts'),
    _CategoryShortcut(label: 'Pants', icon: Icons.straighten_outlined, route: '/category/pants'),
    _CategoryShortcut(label: 'Shoes', icon: Icons.hiking_outlined, route: '/category/shoes'),
    _CategoryShortcut(label: 'Accessories', icon: Icons.watch_outlined, route: '/category/accessories'),
    _CategoryShortcut(label: 'T-Shirts', icon: Icons.style_outlined, route: '/category/tshirts'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _controller.addListener(_onQueryChanged);
    // Auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final raw = await rootBundle.loadString('assets/mock/products.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Product.fromJson(e))
        .toList();
    setState(() {
      _allProducts = list;
      _loading = false;
    });
  }

  void _onQueryChanged() {
    final q = _controller.text.trim().toLowerCase();
    setState(() {
      _hasQuery = q.isNotEmpty;
      if (q.isEmpty) {
        _results = [];
      } else {
        _results = _allProducts.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    final q = query.trim();
    setState(() {
      if (!_recentSearches.contains(q)) {
        _recentSearches.insert(0, q);
        if (_recentSearches.length > 6) _recentSearches.removeLast();
      }
    });
    _focusNode.unfocus();
  }

  void _clearRecent() => setState(() => _recentSearches.clear());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = Theme.of(context).colorScheme.onSurface;
    final inputBg = isDark ? AppColors.grey900 : AppColors.grey100;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context, isDark: isDark, fg: fg, inputBg: inputBg),
            Divider(color: borderColor, height: 1),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent))
                  : _hasQuery
                      ? _buildResults()
                      : _buildDiscovery(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, {required bool isDark, required Color fg, required Color inputBg}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                color: inputBg,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: AppTextStyles.bodyMedium.copyWith(color: fg),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submitSearch,
                  decoration: InputDecoration(
                    hintText: 'Search styles, brands, categories...',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: isDark ? AppColors.grey600 : AppColors.grey400),
                    prefixIcon: Icon(Icons.search,
                        color: isDark ? AppColors.grey500 : AppColors.grey400, size: 20),
                    suffixIcon: _hasQuery
                        ? GestureDetector(
                            onTap: () {
                              _controller.clear();
                              _focusNode.requestFocus();
                            },
                            child: const Icon(Icons.close,
                                color: AppColors.grey500, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.grey900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            if (_hasQuery) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  _focusNode.requestFocus();
                },
                child: Text('CANCEL',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.grey400)),
              ),
            ],
          ],
        ),
      );

  // ── Discovery (no query) ─────────────────────────────────────────
  Widget _buildDiscovery() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subText = isDark ? AppColors.grey500 : AppColors.grey600;
    final itemText = isDark ? AppColors.grey300 : AppColors.grey800;
    final iconColor = isDark ? AppColors.grey600 : AppColors.grey400;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;

    return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              children: [
                Text('RECENT',
                    style: AppTextStyles.labelSmall.copyWith(color: subText)),
                const Spacer(),
                GestureDetector(
                  onTap: _clearRecent,
                  child: Text('CLEAR',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: subText, fontSize: 9)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._recentSearches.map((s) => GestureDetector(
                  onTap: () {
                    _controller.text = s;
                    _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: s.length));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: iconColor, size: 16),
                        const SizedBox(width: 12),
                        Text(s,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: itemText)),
                        const Spacer(),
                        Icon(Icons.north_west, color: iconColor, size: 14),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 24),
            Divider(color: dividerColor),
            const SizedBox(height: 24),
          ],

          // Category shortcuts
          Text('BROWSE BY CATEGORY',
              style: AppTextStyles.labelSmall.copyWith(color: subText)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.6,
            ),
            itemCount: _shortcuts.length,
            itemBuilder: (_, i) => _CategoryShortcutCard(
              shortcut: _shortcuts[i],
              onTap: () => context.push(_shortcuts[i].route),
            ),
          ),

          const SizedBox(height: 28),

          // Trending
          Text('TRENDING NOW',
              style: AppTextStyles.labelSmall.copyWith(color: subText)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Wool Overcoat',
              'Oxford Shirt',
              'Chelsea Boots',
              'Slim Chinos',
              'Merino Knit',
              'Field Jacket',
              'Canvas Sneakers',
              'Leather Belt',
            ]
                .map((term) => GestureDetector(
                      onTap: () {
                        _controller.text = term;
                        _controller.selection =
                            TextSelection.fromPosition(
                                TextPosition(offset: term.length));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: dividerColor),
                        ),
                        child: Text(term,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: itemText)),
                      ),
                    ))
                .toList(),
          ),
        ],
      );
  }

  // ── Results ──────────────────────────────────────────────────────
  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off,
                color: AppColors.grey700, size: 48),
            const SizedBox(height: 16),
            Text('NO RESULTS',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.grey500)),
            const SizedBox(height: 8),
            Text('Try a different search term',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey700)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${_results.length} RESULTS',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.grey500),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.62,
            ),
            itemCount: _results.length,
            itemBuilder: (_, i) =>
                _SearchResultCard(product: _results[i]),
          ),
        ),
      ],
    );
  }
}

// ── Search result card ────────────────────────────────────────────
class _SearchResultCard extends StatelessWidget {
  final Product product;
  const _SearchResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                if (p.isNew)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: AppColors.accent,
                      child: Text('NEW',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.black, fontSize: 9)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(p.name,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('\$${p.price.toStringAsFixed(0)}',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.accent)),
              if (p.hasDiscount) ...[
                const SizedBox(width: 6),
                Text('\$${p.originalPrice!.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                      decoration: TextDecoration.lineThrough,
                    )),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category shortcut ─────────────────────────────────────────────
class _CategoryShortcut {
  final String label;
  final IconData icon;
  final String route;
  const _CategoryShortcut(
      {required this.label, required this.icon, required this.route});
}

class _CategoryShortcutCard extends StatelessWidget {
  final _CategoryShortcut shortcut;
  final VoidCallback onTap;
  const _CategoryShortcutCard(
      {required this.shortcut, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.grey900,
            border: Border.all(color: AppColors.grey800),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(shortcut.icon,
                  color: AppColors.grey400, size: 20),
              const SizedBox(height: 6),
              Text(shortcut.label,
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.grey300, fontSize: 10)),
            ],
          ),
        ),
      );
}