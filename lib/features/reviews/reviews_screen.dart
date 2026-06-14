import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/review.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/shimmer_widgets.dart';

class ReviewsScreen extends StatefulWidget {
  final String productId;
  const ReviewsScreen({super.key, required this.productId});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Review> _reviews = [];
  bool _loading = true;
  bool _showForm = false;

  // Write review form
  int _formRating = 5;
  FitFeedback _formFit = FitFeedback.trueToSize;
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final raw = await rootBundle.loadString('assets/mock/reviews.json');
    final all = (jsonDecode(raw) as List).map((e) => Review.fromJson(e)).toList();
    setState(() {
      _reviews = all.where((r) => r.productId == widget.productId).toList();
      _loading = false;
    });
  }

  double get _avgRating => _reviews.isEmpty
      ? 0
      : _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;

  int _countForRating(int star) => _reviews.where((r) => r.rating == star).length;

  int get _runsSmallCount => _reviews.where((r) => r.fitFeedback == FitFeedback.runsSmall).length;
  int get _trueToSizeCount => _reviews.where((r) => r.fitFeedback == FitFeedback.trueToSize).length;
  int get _runsLargeCount => _reviews.where((r) => r.fitFeedback == FitFeedback.runsLarge).length;

  Future<void> _submitReview() async {
    if (_nameController.text.trim().isEmpty || _commentController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final newReview = Review(
      id: 'r_local_${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.productId,
      userName: _nameController.text.trim(),
      rating: _formRating,
      comment: _commentController.text.trim(),
      fitFeedback: _formFit,
      createdAt: DateTime.now(),
    );
    setState(() {
      _reviews.insert(0, newReview);
      _submitting = false;
      _submitted = true;
      _showForm = false;
      _nameController.clear();
      _commentController.clear();
      _formRating = 5;
      _formFit = FitFeedback.trueToSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('REVIEWS',
            style: AppTextStyles.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: true,
        actions: [
          if (!_showForm)
            TextButton(
              onPressed: () => setState(() => _showForm = true),
              child: Text('WRITE',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent)),
            ),
        ],
      ),
      body: _loading
          ? const ShimmerReviewList()
          : _showForm
              ? _buildWriteForm()
              : _buildReviewList(),
    );
  }

  // ── Review list ───────────────────────────────────────────────
  Widget _buildReviewList() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_border, color: AppColors.grey700, size: 56),
            const SizedBox(height: 16),
            Text('NO REVIEWS YET',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey500)),
            const SizedBox(height: 8),
            Text('Be the first to review this item',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey700)),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => setState(() => _showForm = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                color: AppColors.accent,
                child: Text('WRITE A REVIEW',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.black)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (_submitted) _buildSuccessBanner(),
        _buildSummary(),
        const SizedBox(height: 24),
        _buildFitFeedback(),
        const SizedBox(height: 28),
        Text('${_reviews.length} REVIEWS',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        ..._reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }

  Widget _buildSuccessBanner() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.accent),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Text('Your review has been posted!',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent)),
          ],
        ),
      );

  Widget _buildSummary() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big average rating
          Column(
            children: [
              Text(
                _avgRating.toStringAsFixed(1),
                style: AppTextStyles.display.copyWith(
                    color: AppColors.white, fontSize: 56, height: 1),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < _avgRating.round() ? Icons.star : Icons.star_border,
                  color: AppColors.accent,
                  size: 14,
                )),
              ),
              const SizedBox(height: 4),
              Text('${_reviews.length} reviews',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
            ],
          ),
          const SizedBox(width: 24),
          // Distribution bars
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = _countForRating(star);
                final pct = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text('$star',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.grey400, fontSize: 10)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: AppColors.accent, size: 10),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.grey800,
                            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.grey500, fontSize: 10)),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      );

  Widget _buildFitFeedback() {
    final total = _reviews.length;
    if (total == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FIT',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey900,
            border: Border.all(color: AppColors.grey800),
          ),
          child: Column(
            children: [
              // Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Row(
                  children: [
                    if (_runsSmallCount > 0)
                      Flexible(
                        flex: _runsSmallCount,
                        child: Container(height: 8, color: AppColors.error.withValues(alpha: 0.7)),
                      ),
                    if (_trueToSizeCount > 0)
                      Flexible(
                        flex: _trueToSizeCount,
                        child: Container(height: 8, color: AppColors.accent),
                      ),
                    if (_runsLargeCount > 0)
                      Flexible(
                        flex: _runsLargeCount,
                        child: Container(height: 8, color: AppColors.grey600),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FitLabel('Runs Small', _runsSmallCount, total, AppColors.error.withValues(alpha: 0.7)),
                  _FitLabel('True to Size', _trueToSizeCount, total, AppColors.accent),
                  _FitLabel('Runs Large', _runsLargeCount, total, AppColors.grey600),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Write review form ─────────────────────────────────────────
  Widget _buildWriteForm() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('WRITE A REVIEW',
              style: AppTextStyles.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 24),
          // Star rating picker
          Text('YOUR RATING',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _formRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  i < _formRating ? Icons.star : Icons.star_border,
                  color: AppColors.accent,
                  size: 32,
                ),
              ),
            )),
          ),
          const SizedBox(height: 24),
          // Fit feedback
          Text('FIT',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              _FitChip(label: 'Runs Small', selected: _formFit == FitFeedback.runsSmall,
                  onTap: () => setState(() => _formFit = FitFeedback.runsSmall)),
              const SizedBox(width: 8),
              _FitChip(label: 'True to Size', selected: _formFit == FitFeedback.trueToSize,
                  onTap: () => setState(() => _formFit = FitFeedback.trueToSize)),
              const SizedBox(width: 8),
              _FitChip(label: 'Runs Large', selected: _formFit == FitFeedback.runsLarge,
                  onTap: () => setState(() => _formFit = FitFeedback.runsLarge)),
            ],
          ),
          const SizedBox(height: 24),
          // Name
          Text('YOUR NAME',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400, letterSpacing: 1.5, fontSize: 10)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            decoration: _inputDecoration('e.g. John M.'),
          ),
          const SizedBox(height: 16),
          // Comment
          Text('YOUR REVIEW',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400, letterSpacing: 1.5, fontSize: 10)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            maxLines: 4,
            decoration: _inputDecoration('Share your experience with this item...'),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showForm = false),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey700),
                    ),
                    child: Text('CANCEL',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _submitting ? null : _submitReview,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    color: AppColors.accent,
                    child: _submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.black, strokeWidth: 2))
                        : Text('POST REVIEW',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.black)),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        filled: true,
        fillColor: AppColors.grey900,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.grey700)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.grey700)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.accent)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

// ── Review card ───────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final fitLabel = review.fitFeedback == FitFeedback.runsSmall
        ? 'Runs Small'
        : review.fitFeedback == FitFeedback.runsLarge
            ? 'Runs Large'
            : 'True to Size';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border.all(color: AppColors.grey800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                color: AppColors.grey800,
                alignment: Alignment.center,
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                    Text(
                      _formatDate(review.createdAt),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey600, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  color: AppColors.accent,
                  size: 12,
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey300, height: 1.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey700),
            ),
            child: Text(fitLabel,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.grey400, fontSize: 9, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_month(dt.month)} ${dt.year}';

  String _month(int m) => [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ── Helpers ───────────────────────────────────────────────────────
class _FitLabel extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _FitLabel(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('${(count / total * 100).round()}%',
              style: AppTextStyles.labelMedium.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.grey500, fontSize: 9)),
        ],
      );
}

class _FitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FitChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.grey700),
          ),
          child: Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? AppColors.accent : AppColors.grey500,
                fontSize: 10,
              )),
        ),
      );
}
