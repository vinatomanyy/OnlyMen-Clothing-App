import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

// Base shimmer box — dark theme
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 2,
  });

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.grey800,
        highlightColor: AppColors.grey700,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.grey800,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
}

// ── Product grid shimmer (2-column) ──────────────────────────────
class ShimmerProductGrid extends StatelessWidget {
  final int count;
  const ShimmerProductGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.62,
        ),
        itemCount: count,
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ShimmerBox(height: double.infinity)),
            SizedBox(height: 8),
            ShimmerBox(height: 12, width: 120),
            SizedBox(height: 6),
            ShimmerBox(height: 12, width: 60),
          ],
        ),
      );
}

// ── Product list shimmer (horizontal card) ────────────────────────
class ShimmerProductList extends StatelessWidget {
  final int count;
  const ShimmerProductList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 130,
          child: const Row(
            children: [
              ShimmerBox(width: 110, height: 130),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(height: 14, width: double.infinity),
                    SizedBox(height: 8),
                    ShimmerBox(height: 12, width: 100),
                    SizedBox(height: 8),
                    ShimmerBox(height: 12, width: 60),
                    SizedBox(height: 12),
                    ShimmerBox(height: 32, width: double.infinity),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Branch list shimmer ───────────────────────────────────────────
class ShimmerBranchList extends StatelessWidget {
  final int count;
  const ShimmerBranchList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(height: 14, width: 180),
              SizedBox(height: 8),
              ShimmerBox(height: 12, width: double.infinity),
              SizedBox(height: 6),
              ShimmerBox(height: 12, width: 120),
              SizedBox(height: 12),
              ShimmerBox(height: 36, width: double.infinity),
            ],
          ),
        ),
      );
}

// ── Product detail shimmer ────────────────────────────────────────
class ShimmerProductDetail extends StatelessWidget {
  const ShimmerProductDetail({super.key});

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(height: 420),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(height: 24, width: 200),
                  SizedBox(height: 12),
                  ShimmerBox(height: 18, width: 100),
                  SizedBox(height: 24),
                  ShimmerBox(height: 14, width: double.infinity),
                  SizedBox(height: 8),
                  ShimmerBox(height: 14, width: double.infinity),
                  SizedBox(height: 8),
                  ShimmerBox(height: 14, width: 160),
                  SizedBox(height: 24),
                  Row(children: [
                    ShimmerBox(width: 48, height: 48),
                    SizedBox(width: 8),
                    ShimmerBox(width: 48, height: 48),
                    SizedBox(width: 8),
                    ShimmerBox(width: 48, height: 48),
                  ]),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Review list shimmer ───────────────────────────────────────────
class ShimmerReviewList extends StatelessWidget {
  const ShimmerReviewList({super.key});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 36, height: 36),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerBox(height: 12, width: 120)),
                ],
              ),
              SizedBox(height: 12),
              ShimmerBox(height: 12, width: double.infinity),
              SizedBox(height: 6),
              ShimmerBox(height: 12, width: 200),
            ],
          ),
        ),
      );
}

// ── Masonry grid shimmer ──────────────────────────────────────────
class ShimmerMasonryGrid extends StatelessWidget {
  const ShimmerMasonryGrid({super.key});

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (_, i) => ShimmerBox(
          height: i % 3 == 0 ? 220 : i % 3 == 1 ? 160 : 190,
        ),
      );
}
