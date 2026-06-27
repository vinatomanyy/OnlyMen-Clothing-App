import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/branch.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class BranchMapView extends StatelessWidget {
  final List<Branch> branches;
  final int selectedIndex;
  final ValueChanged<int> onBranchTap;

  const BranchMapView({
    super.key,
    required this.branches,
    required this.selectedIndex,
    required this.onBranchTap,
  });

  static const _fallbackCenter = LatLng(11.5565, 104.9210);

  @override
  Widget build(BuildContext context) {
    final center = branches.isEmpty
        ? _fallbackCenter
        : LatLng(
            branches.map((b) => b.lat).reduce((a, b) => a + b) / branches.length,
            branches.map((b) => b.lng).reduce((a, b) => a + b) / branches.length,
          );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13.2,
        minZoom: 11,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.yourname.onlymen',
        ),
        MarkerLayer(
          markers: branches.asMap().entries.map((entry) {
            final index = entry.key;
            final branch = entry.value;
            return Marker(
              point: LatLng(branch.lat, branch.lng),
              width: 96,
              height: 64,
              child: GestureDetector(
                onTap: () => onBranchTap(index),
                child: _BranchMarker(
                  label: '${index + 1}',
                  selected: index == selectedIndex,
                  name: branch.name,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BranchMarker extends StatelessWidget {
  final String label;
  final String name;
  final bool selected;

  const _BranchMarker({
    required this.label,
    required this.name,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.85),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                  fontSize: 9,
                ),
              ),
            ),
          const SizedBox(height: 2),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.black,
                fontSize: 10,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 8,
            color: selected ? AppColors.accent : AppColors.white,
          ),
        ],
      );
}
