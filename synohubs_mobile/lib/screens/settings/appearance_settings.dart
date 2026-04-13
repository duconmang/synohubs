import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../l10n/app_localizations.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  int _selectedTheme = 0; // 0=Dark, 1=Light, 2=System
  int _selectedAccent = 0; // 0=Cyan, 1=Teal, 2=Gold, 3=Purple

  static const _themeIcons = [
    Icons.dark_mode,
    Icons.light_mode,
    Icons.phone_android,
  ];

  static const _accentColors = [
    AppColors.primaryContainer, // Cyan
    AppColors.secondary, // Teal
    AppColors.tertiary, // Gold
    Color(0xFFB388FF), // Purple
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final themeOptions = [l.dark, l.light, l.system];
    final accentNames = [l.cyan, l.teal, l.gold, l.purple];
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.themeAndColors,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Theme ──
            _sectionLabel(l.theme),
            const SizedBox(height: 12),
            Row(
              children: List.generate(3, (i) {
                final selected = _selectedTheme == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTheme = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      child: GlassCard(
                        borderRadius: 20,
                        hasGlow: selected,
                        borderColor: selected
                            ? AppColors.primaryContainer
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(
                              _themeIcons[i],
                              color: selected
                                  ? AppColors.primaryContainer
                                  : AppColors.onSurfaceVariant,
                              size: 28,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              themeOptions[i],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.onSurface
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // ── Accent Color ──
            _sectionLabel(l.accentColor),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(_accentColors.length, (i) {
                  final selected = _selectedAccent == i;
                  return Column(
                    children: [
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Divider(
                            height: 1,
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                      InkWell(
                        onTap: () => setState(() => _selectedAccent = i),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _accentColors[i],
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accentColors[i].withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  accentNames[i],
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? _accentColors[i]
                                        : AppColors.outlineVariant,
                                    width: selected ? 2 : 1.5,
                                  ),
                                  color: selected
                                      ? _accentColors[i].withValues(alpha: 0.2)
                                      : Colors.transparent,
                                ),
                                child: selected
                                    ? Icon(
                                        Icons.check,
                                        size: 14,
                                        color: _accentColors[i],
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 32),

            // ── Preview ──
            _sectionLabel(l.preview),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 22,
              hasGlow: true,
              borderColor: _accentColors[_selectedAccent],
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _accentColors[_selectedAccent].withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.palette,
                          color: _accentColors[_selectedAccent],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SynoHub',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _accentColors[_selectedAccent],
                              ),
                            ),
                            Text(
                              l.accentColorPreview,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        _accentColors[_selectedAccent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
