import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/branch.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../widgets/branch_map_view.dart';

void _showTryOnSheet(BuildContext context, Branch branch) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cardDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => Padding(
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
          const SizedBox(height: 4),
          Text(
            branch.address,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 20),
          Text(
            'Reserve a fitting room and our stylists will have your selected items ready when you arrive.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.grey300, height: 1.6),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final uri = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=${branch.lat},${branch.lng}',
                    );
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey700),
                    ),
                    child: Text(
                      'DIRECTIONS',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/booking'),
                  child: Container(
                    height: 48,
                    color: AppColors.accent,
                    alignment: Alignment.center,
                    child: Text(
                      'BOOK',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _loading
          ? const ShimmerBranchList()
          : Column(
              children: [
                // Map view
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  height: _mapExpanded ? 280 : 140,
                  child: BranchMapView(
                    branches: _branches,
                    selectedIndex: _selectedIndex,
                    onBranchTap: (i) {
                      setState(() => _selectedIndex = i);
                      _showTryOnSheet(context, _branches[i]);
                    },
                  ),
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
                      index: i + 1,
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'NEARBY BOUTIQUES',
          style:
              AppTextStyles.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface),
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

  }

// ── Branch card ───────────────────────────────────────────────────
class _BranchCard extends StatelessWidget {
  final Branch branch;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _BranchCard({
    required this.branch,
    required this.index,
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
                    '$index',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  color: isOpen
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
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
                      onTap: () {
                      final uri = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=${branch.lat},${branch.lng}');
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
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

  bool _isOpenNow(String hours) {
    final now = TimeOfDay.now();
    // Simple check: assume open 10am–9pm/10pm
    return now.hour >= 10 && now.hour < 21;
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
// (previously provided an alias) Removed duplicate MapScreen alias.
