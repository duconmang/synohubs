import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/user_group_screen.dart';
import '../services/session_manager.dart';

class SynoHubAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? avatarUrl;
  final VoidCallback? onDisconnect;

  const SynoHubAppBar({super.key, this.avatarUrl, this.onDisconnect});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isAdmin = SessionManager.instance.isAdmin;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppColors.slate950.withValues(alpha: 0.8),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: isAdmin
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserGroupScreen(),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: avatarUrl != null
                          ? Image.network(avatarUrl!, fit: BoxFit.cover)
                          : const Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 24,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SynoHub',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cyan400,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (onDisconnect != null)
                    _buildIconButton(Icons.swap_horiz, onDisconnect!),
                  if (onDisconnect != null) const SizedBox(width: 8),
                  _buildIconButton(Icons.settings_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.slate800.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.cyan400, size: 22),
      ),
    );
  }
}
