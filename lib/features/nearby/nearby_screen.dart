import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/branch.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  List<Branch> _branches = [];
  bool _loading = true;
  int _selectedIndex = 0;
  bool _mapExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final raw =
        await rootBundle.loadString('assets/mock/branches.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Branch.fromJson(e))
        .toList();
    setState(() {
      _branches = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                // Map view
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  height: _mapExpanded ? 280 : 140,
                  child: _buildMockMap(),
                ),
                // Toggle map size
                GestureDetector(
                  onTap: () =>
                      setState(() => _mapExpanded = !_mapExpanded),
                  child: Container(
                    height: 28,
                    color: AppColors.grey900,
                    alignment: Alignment.center,
                    child: Icon(
                      _mapExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.grey500,
                      size: 18,
                    ),
                  ),
                ),
                // Branch list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _branches.length,
                    itemBuilder: (_, i) => _BranchCard(
                      branch: _branches[i],
                      selected: i == _selectedIndex,
                      onTap: () => setState(() => _selectedIndex = i),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'NEARBY BOUTIQUES',
          style:
              AppTextStyles.labelLarge.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location,
                color: AppColors.accent, size: 20),
            onPressed: () {},
          ),
        ],
      );

  Widget _buildMockMap() {
    // Mock map using CustomPainter — no google_maps dependency needed
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _MockMapPainter(
            branches: _branches,
            selectedIndex: _selectedIndex,
          ),
        ),
        // Map attribution
        Positioned(
          bottom: 6,
          right: 8,
          child: Text(
            'Map view (mock)',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.grey700, fontSize: 9),
          ),
        ),
        // Map pins overlay
        ..._branches.asMap().entries.map((entry) {
          final i = entry.key;
          final b = entry.value;
          // Normalize lat/lng to screen position (rough)
          final minLat = 11.565, maxLat = 11.590;
          final minLng = 104.880, maxLng = 104.930;
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final x = ((b.lng - minLng) / (maxLng - minLng)) * w;
              final y =
                  (1 - (b.lat - minLat) / (maxLat - minLat)) * h;
              return Positioned(
                left: x.clamp(20.0, w - 20.0) - 16,
                top: y.clamp(20.0, h - 40.0) - 32,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: _MapPin(
                    label: '${i + 1}',
                    selected: i == _selectedIndex,
                    distKm: b.distanceKm,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// ── Map pin ───────────────────────────────────────────────────────
class _MapPin extends StatelessWidget {
  final String label;
  final bool selected;
  final double distKm;

  const _MapPin({
    required this.label,
    required this.selected,
    required this.distKm,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              color: AppColors.black.withOpacity(0.8),
              child: Text(
                '${distKm}km',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent, fontSize: 10),
              ),
            ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.black,
                fontSize: 11,
              ),
            ),
          ),
          // Pin tail
          Container(
            width: 2,
            height: 8,
            color: selected ? AppColors.accent : AppColors.white,
          ),
        ],
      );
}

// ── Branch card ───────────────────────────────────────────────────
class _BranchCard extends StatelessWidget {
  final Branch branch;
  final bool selected;
  final VoidCallback onTap;

  const _BranchCard({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = _isOpenNow(branch.hours);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.grey900 : AppColors.cardDark,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.grey800,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number badge
                Container(
                  width: 24,
                  height: 24,
                  color: selected ? AppColors.accent : AppColors.grey800,
                  alignment: Alignment.center,
                  child: Text(
                    '${_branchIndex(branch)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected
                          ? AppColors.black
                          : AppColors.grey400,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        branch.address,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
                // Distance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${branch.distanceKm} km',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.accent),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: isOpen
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.error.withOpacity(0.15),
                      child: Text(
                        isOpen ? 'OPEN' : 'CLOSED',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isOpen
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.grey800, height: 1),
            const SizedBox(height: 12),
            // Hours + phone
            Row(
              children: [
                const Icon(Icons.access_time,
                    color: AppColors.grey600, size: 13),
                const SizedBox(width: 6),
                Text(
                  branch.hours,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey400, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    color: AppColors.grey600, size: 13),
                const SizedBox(width: 6),
                Text(
                  branch.phone,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey400, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'DIRECTIONS',
                    icon: Icons.directions_outlined,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'TRY ON IN STORE',
                    icon: Icons.checkroom_outlined,
                    filled: true,
                    onTap: () => _showTryOnSheet(context, branch),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _branchIndex(Branch b) {
    // Return 1-based index based on distanceKm order
    return (b.distanceKm * 10).round() % 10 == 8 ? 1 :
           (b.distanceKm * 10).round() % 10 == 2 ? 2 : 3;
  }

  bool _isOpenNow(String hours) {
    final now = TimeOfDay.now();
    // Simple check: assume open 10am–9pm/10pm
    return now.hour >= 10 && now.hour < 21;
  }

  void _showTryOnSheet(BuildContext context, Branch branch) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TRY ON IN STORE',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.white)),
            const SizedBox(height: 8),
            Text(
              branch.name,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey400),
            ),
            const SizedBox(height: 20),
            Text(
              'Reserve a fitting room and our stylists will have your selected items ready when you arrive.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey300, height: 1.6),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/booking');
              },
              child: Container(
                height: 52,
                color: AppColors.accent,
                alignment: Alignment.center,
                child: Text(
                  'BOOK FITTING ROOM',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.black),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey700),
                ),
                child: Text(
                  'CANCEL',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : Colors.transparent,
            border: Border.all(
              color: filled ? AppColors.accent : AppColors.grey700,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 13,
                  color:
                      filled ? AppColors.black : AppColors.grey400),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: filled ? AppColors.black : AppColors.grey400,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Mock map painter ──────────────────────────────────────────────
class _MockMapPainter extends CustomPainter {
  final List<Branch> branches;
  final int selectedIndex;

  _MockMapPainter({required this.branches, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark map background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    final roadPaint = Paint()
      ..color = const Color(0xFF2A2A3E)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final roadPaintLight = Paint()
      ..color = const Color(0xFF333355)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final blockPaint = Paint()
      ..color = const Color(0xFF151525)
      ..style = PaintingStyle.fill;

    // Draw city blocks
    final rng = math.Random(42);
    for (int i = 0; i < 12; i++) {
      for (int j = 0; j < 8; j++) {
        final x = i * (size.width / 11) + rng.nextDouble() * 8;
        final y = j * (size.height / 7) + rng.nextDouble() * 8;
        final w = 30 + rng.nextDouble() * 40;
        final h = 20 + rng.nextDouble() * 30;
        canvas.drawRect(
          Rect.fromLTWH(x, y, w, h),
          blockPaint,
        );
      }
    }

    // Main roads horizontal
    for (double y in [
      size.height * 0.2,
      size.height * 0.45,
      size.height * 0.7
    ]) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), roadPaint);
    }
    // Main roads vertical
    for (double x in [
      size.width * 0.25,
      size.width * 0.5,
      size.width * 0.75
    ]) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    // Secondary roads
    for (double y in [
      size.height * 0.32,
      size.height * 0.58,
      size.height * 0.83
    ]) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), roadPaintLight);
    }
    for (double x in [
      size.width * 0.12,
      size.width * 0.37,
      size.width * 0.62,
      size.width * 0.87
    ]) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), roadPaintLight);
    }

    // User location dot
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.6;
    canvas.drawCircle(
      Offset(centerX, centerY),
      10,
      Paint()
        ..color = const Color(0xFF4A90D9).withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      5,
      Paint()
        ..color = const Color(0xFF4A90D9)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      5,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_MockMapPainter old) =>
      old.selectedIndex != selectedIndex;
}
