import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/promotion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  List<Promotion> _promos = [];
  bool _loading = true;
  final Set<String> _copiedCodes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('assets/mock/promotions.json');
    final promos = (jsonDecode(raw) as List)
        .map((e) => Promotion.fromJson(e))
        .toList();
    setState(() {
      _promos = promos;
      _loading = false;
    });
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedCodes.add(code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $code copied!',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.black)),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          children: [
            Text(
              'PROMOTIONS',
              style: AppTextStyles.labelLarge
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            if (!_loading && _promos.isNotEmpty)
              Text(
                '${_promos.length} offers',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey500, fontSize: 11),
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _promos.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: _promos.length,
                  itemBuilder: (_, i) => _CouponCard(
                    promo: _promos[i],
                    copied: _copiedCodes.contains(_promos[i].code),
                    onCopy: () => _copyCode(_promos[i].code),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer_outlined,
                color: AppColors.grey700, size: 64),
            const SizedBox(height: 16),
            Text('NO PROMOTIONS',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.grey500)),
            const SizedBox(height: 8),
            Text('Check back later for exclusive deals',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey700)),
          ],
        ),
      );
}

class _CouponCard extends StatelessWidget {
  final Promotion promo;
  final bool copied;
  final VoidCallback onCopy;

  const _CouponCard({
    required this.promo,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = promo.expiryDate.difference(DateTime.now()).inDays;
    final expired = promo.isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: badge + expiry
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  color: AppColors.error,
                  child: Text(
                    '-${promo.discountPercent}% OFF',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  expired
                      ? 'EXPIRED'
                      : daysLeft == 0
                          ? 'Expires today'
                          : '$daysLeft days left',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: expired ? AppColors.error : AppColors.grey500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              promo.title,
              style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              promo.description,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.grey500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),
            // Code + actions row
            Row(
              children: [
                // Copy code box
                GestureDetector(
                  onTap: expired ? null : onCopy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: expired
                            ? AppColors.grey800
                            : copied
                                ? AppColors.accent
                                : AppColors.grey700,
                      ),
                      color: copied
                          ? AppColors.accent.withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          promo.code,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: expired
                                ? AppColors.grey700
                                : copied
                                    ? AppColors.accent
                                    : Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          copied ? Icons.check : Icons.copy_outlined,
                          color: expired
                              ? AppColors.grey800
                              : copied
                                  ? AppColors.accent
                                  : AppColors.grey500,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Use Now button
                if (!expired)
                  GestureDetector(
                    onTap: () => context.push('/category/all'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: AppColors.accent,
                      child: Text(
                        'USE NOW',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.black,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
