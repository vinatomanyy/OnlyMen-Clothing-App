import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/supabase_repository.dart';
import '../../models/product.dart';
import '../../state/card_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_image.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoController = TextEditingController();
  String? _appliedPromo;
  String? _promoError;
  double _discount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCartPrices());
  }

  Future<void> _refreshCartPrices() async {
    final items = ref.read(cartProvider);
    if (items.isEmpty) return;
    final ids = items.map((e) => e.product.id).toSet().toList();
    final fresh = await Future.wait(ids.map(SupabaseRepository.getProductById));
    final map = <String, Product>{};
    for (final p in fresh) {
      if (p != null) map[p.id] = p;
    }
    ref.read(cartProvider.notifier).refreshPrices(map);
  }

  // Mock valid promo codes
  final _promoCodes = {
    'SEASON30': 0.30,
    'WELCOME15': 0.15,
    'WEEKEND20': 0.20,
    'LOYAL10': 0.10,
    'BUNDLE25': 0.25,
    'WINTER20': 0.20,
  };

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (_promoCodes.containsKey(code)) {
      setState(() {
        _appliedPromo = code;
        _discount = _promoCodes[code]!;
        _promoError = null;
      });
    } else {
      setState(() {
        _appliedPromo = null;
        _discount = 0;
        _promoError = 'Invalid promo code';
      });
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _discount = 0;
      _promoError = null;
      _promoController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final discountAmt = subtotal * _discount;
    final total = subtotal - discountAmt;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, items.length),
      body: items.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      ...items.map((item) => _CartItemCard(
                            item: item,
                            onIncrement: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  item.product.id,
                                  item.size,
                                  item.colorName,
                                  item.quantity + 1,
                                ),
                            onDecrement: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  item.product.id,
                                  item.size,
                                  item.colorName,
                                  item.quantity - 1,
                                ),
                            onRemove: () => ref
                                .read(cartProvider.notifier)
                                .remove(
                                  item.product.id,
                                  item.size,
                                  item.colorName,
                                ),
                          )),
                      const SizedBox(height: 24),
                      _buildPromoSection(),
                      const SizedBox(height: 24),
                      _buildOrderSummary(
                          subtotal, discountAmt, total),
                    ],
                  ),
                ),
                _buildCheckoutBar(context, total, items.isEmpty),
              ],
            ),
    );
  }

  AppBar _buildAppBar(BuildContext context, int count) => AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'MY BAG ($count)',
          style: AppTextStyles.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: [
          if (count > 0)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: Text(
                'CLEAR',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.grey500),
              ),
            ),
        ],
      );

  Widget _buildEmptyCart(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                color: AppColors.grey700, size: 64),
            const SizedBox(height: 16),
            Text('YOUR BAG IS EMPTY',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.grey500)),
            const SizedBox(height: 8),
            Text('Add items to get started',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey700)),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                color: AppColors.white,
                child: Text('SHOP NOW',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.black)),
              ),
            ),
          ],
        ),
      );

  Widget _buildPromoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROMO CODE',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
          const SizedBox(height: 10),
          if (_appliedPromo != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent),
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '$_appliedPromo applied — ${(_discount * 100).toInt()}% off',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.accent),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _removePromo,
                    child: const Icon(Icons.close,
                        color: AppColors.grey500, size: 16),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Theme.of(context).colorScheme.onSurface),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter code',
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey500),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      errorText: _promoError,
                      errorStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _applyPromo,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: AppColors.accent,
                    alignment: Alignment.center,
                    child: Text('APPLY',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.black)),
                  ),
                ),
              ],
            ),
        ],
      );

  Widget _buildOrderSummary(
      double subtotal, double discountAmt, double total) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            _SummaryRow(label: 'Subtotal', value: '\$${subtotal.toStringAsFixed(2)}'),
            if (_discount > 0) ...[
              const SizedBox(height: 10),
              _SummaryRow(
                label: 'Discount (${(_discount * 100).toInt()}%)',
                value: '-\$${discountAmt.toStringAsFixed(2)}',
                valueColor: AppColors.accent,
              ),
            ],
            const SizedBox(height: 10),
            _SummaryRow(
                label: 'Shipping', value: 'FREE', valueColor: AppColors.success),
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'TOTAL',
              value: '\$${total.toStringAsFixed(2)}',
              labelStyle: AppTextStyles.labelLarge
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
              valueStyle: AppTextStyles.price.copyWith(fontSize: 18),
            ),
          ],
        ),
      );

  Widget _buildCheckoutBar(
          BuildContext context, double total, bool isEmpty) =>
      Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: GestureDetector(
          onTap: isEmpty
              ? null
              : () => context.push('/checkout?total=${total.toStringAsFixed(2)}'),
          child: Container(
            height: 52,
            color: isEmpty ? AppColors.grey800 : AppColors.accent,
            alignment: Alignment.center,
            child: Text(
              isEmpty
                  ? 'YOUR BAG IS EMPTY'
                  : 'CHECKOUT — \$${total.toStringAsFixed(2)}',
              style: AppTextStyles.labelLarge.copyWith(
                color: isEmpty ? AppColors.grey600 : AppColors.black,
              ),
            ),
          ),
        ),
      );
}

// Cart item card
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return Dismissible(
      key: Key('${p.id}_${item.size}_${item.colorName}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withValues(alpha: 0.15),
        child: const Icon(Icons.delete_outline,
            color: AppColors.error, size: 22),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            AppImage(
              url: p.images.first,
              fit: BoxFit.cover,
              width: 90,
              height: 110,
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(p.name,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 2),
                      ),
                      GestureDetector(
                        onTap: onRemove,
                        child: const Icon(Icons.close,
                            color: AppColors.grey600, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.colorName} · Size ${item.size}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '\$${(p.price * item.quantity).toStringAsFixed(2)}',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.accent),
                      ),
                      const Spacer(),
                      // Quantity controls
                      _QuantityControl(
                        quantity: item.quantity,
                        onDecrement: onDecrement,
                        onIncrement: onIncrement,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _QtyBtn(icon: Icons.remove, onTap: onDecrement),
          Container(
            width: 36,
            height: 30,
            alignment: Alignment.center,
            color: Theme.of(context).cardColor,
            child: Text(
              '$quantity',
              style: AppTextStyles.labelMedium
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          _QtyBtn(icon: Icons.add, onTap: onIncrement),
        ],
      );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          color: Theme.of(context).dividerColor,
          child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 14),
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: labelStyle ??
                  AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey400)),
          const Spacer(),
          Text(value,
              style: valueStyle ??
                  AppTextStyles.bodySmall.copyWith(
                      color: valueColor ?? Theme.of(context).colorScheme.onSurface)),
        ],
      );
}