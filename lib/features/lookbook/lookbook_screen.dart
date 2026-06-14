import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/lookbook.dart';
import '../../models/product.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LookbookScreen extends StatefulWidget {
  const LookbookScreen({super.key});

  @override
  State<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends State<LookbookScreen> {
  List<Lookbook> _lookbooks = [];
  List<Product> _allProducts = [];
  bool _loading = true;
  int _currentPage = 0;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final lbRaw = await rootBundle.loadString('assets/mock/lookbooks.json');
    final pRaw = await rootBundle.loadString('assets/mock/products.json');

    final lookbooks = (jsonDecode(lbRaw) as List)
        .map((e) => Lookbook.fromJson(e))
        .toList();
    final products = (jsonDecode(pRaw) as List)
        .map((e) => Product.fromJson(e))
        .toList();

    setState(() {
      _lookbooks = lookbooks;
      _allProducts = products;
      _loading = false;
    });
  }

  List<Product> _productsForLookbook(Lookbook lb) => lb.productIds
      .map((id) => _allProducts.where((p) => p.id == id).firstOrNull)
      .whereType<Product>()
      .toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Full screen horizontal page swipe
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: _lookbooks.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _LookbookPage(
              lookbook: _lookbooks[i],
              products: _productsForLookbook(_lookbooks[i]),
              index: i,
              total: _lookbooks.length,
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Page counter bottom right
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            right: 24,
            child: _buildPageCounter(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.white, size: 20),
                ),
              ),
              const Spacer(),
              Text(
                'LOOKBOOK',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 40), // balance
            ],
          ),
        ),
      );

  Widget _buildPageCounter() => Row(
        children: List.generate(
          _lookbooks.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(left: 4),
            width: _currentPage == i ? 24 : 6,
            height: 2,
            color: _currentPage == i ? AppColors.accent : AppColors.grey700,
          ),
        ),
      );
}

class _LookbookPage extends StatefulWidget {
  final Lookbook lookbook;
  final List<Product> products;
  final int index;
  final int total;

  const _LookbookPage({
    required this.lookbook,
    required this.products,
    required this.index,
    required this.total,
  });

  @override
  State<_LookbookPage> createState() => _LookbookPageState();
}

class _LookbookPageState extends State<_LookbookPage>
    with SingleTickerProviderStateMixin {
  bool _productsVisible = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleProducts() {
    setState(() => _productsVisible = !_productsVisible);
    if (_productsVisible) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _toggleProducts,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full bleed editorial image
            Image.network(
              widget.lookbook.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.grey900,
                child: const Icon(Icons.image_not_supported,
                    color: AppColors.grey700, size: 64),
              ),
            ),

            // Gradient overlay bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.7),
                      AppColors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Editorial text + products
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Issue label
                      Text(
                        'ISSUE ${widget.index + 1} / ${widget.total}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Lookbook title
                      Text(
                        widget.lookbook.title.toUpperCase(),
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.white,
                          fontSize: 38,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tap hint / hide hint
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _productsVisible
                            ? const SizedBox.shrink()
                            : GestureDetector(
                                onTap: _toggleProducts,
                                child: Row(
                                  children: [
                                    Text(
                                      'SHOP THE LOOK',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward,
                                        color: AppColors.white, size: 14),
                                  ],
                                ),
                              ),
                      ),

                      // Product cards reveal
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: _productsVisible
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 170,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: widget.products.length,
                                        itemBuilder: (_, i) =>
                                            _LookbookProductCard(
                                          product: widget.products[i],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: _toggleProducts,
                                      child: Row(
                                        children: [
                                          Text(
                                            'CLOSE',
                                            style:
                                                AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.grey400,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.keyboard_arrow_down,
                                              color: AppColors.grey400, size: 14),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Swipe hint arrows (only when products hidden)
            if (!_productsVisible) ...[
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: widget.index < widget.total - 1
                      ? const Icon(Icons.chevron_right,
                          color: Colors.white24, size: 32)
                      : const SizedBox.shrink(),
                ),
              ),
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: widget.index > 0
                      ? const Icon(Icons.chevron_left,
                          color: Colors.white24, size: 32)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LookbookProductCard extends StatelessWidget {
  final Product product;
  const _LookbookProductCard({required this.product});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push('/product/${product.id}'),
        child: Container(
          width: 110,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.grey900.withValues(alpha: 0.85),
            border: Border.all(color: AppColors.grey800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              SizedBox(
                height: 110,
                child: Image.network(
                  product.images.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.grey800),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.white, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(0)}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.accent, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}