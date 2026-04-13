import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Set<int> premiumIndices;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.premiumIndices = const {},
  });

  static List<_NavItem> _getItems(AppLocalizations l) => [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: l.dashboard,
    ),
    _NavItem(
      icon: Icons.folder_open_outlined,
      activeIcon: Icons.folder_open,
      label: l.files,
    ),
    _NavItem(
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle,
      label: l.media,
    ),
    _NavItem(
      icon: Icons.image_outlined,
      activeIcon: Icons.image,
      label: l.photos,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = _getItems(l);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.slate950.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: AppColors.slate800.withValues(alpha: 0.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.05),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isActive = index == currentIndex;
                  final isPremium = premiumIndices.contains(index);
                  return _buildNavItem(
                    item,
                    isActive,
                    isPremium,
                    () => onTap(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    _NavItem item,
    bool isActive,
    bool isPremium,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.cyan400.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isPremium
                      ? AppColors.slate500.withValues(alpha: 0.5)
                      : isActive
                      ? AppColors.cyan400
                      : AppColors.slate500,
                  size: 24,
                ),
                if (isPremium)
                  const Positioned(
                    right: -6,
                    top: -4,
                    child: Icon(Icons.lock, size: 12, color: Color(0xFFFFD700)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: isPremium
                    ? AppColors.slate500.withValues(alpha: 0.5)
                    : isActive
                    ? AppColors.cyan400
                    : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
