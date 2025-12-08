import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF2A2A30).withOpacity(0.96),
                        const Color(0xFF1E1E23).withOpacity(0.96),
                      ]
                    : [
                        Colors.white.withOpacity(0.94),
                        Colors.white.withOpacity(0.90),
                      ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.white.withOpacity(0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 50,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, color: primary, size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            'Cài đặt',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Color Theme Picker
                      _SectionTitle(icon: Icons.palette_rounded, title: 'Màu chủ đạo'),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: AppColorTheme.values.map((theme) {
                          final isSelected = provider.colorTheme == theme;
                          final color = AppTheme.primaryColors[theme]!;
                          return GestureDetector(
                            onTap: () => context.read<AppProvider>().setColorTheme(theme),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: isSelected ? 48 : 40,
                              height: isSelected ? 48 : 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [color, color.withOpacity(0.7)],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.45),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      _Divider(isDark: isDark),
                      const SizedBox(height: 18),
                      
                      // Toggles
                      _SettingSwitch(
                        icon: Icons.dark_mode_rounded,
                        label: 'Chế độ tối',
                        subtitle: 'Giao diện tối cho ban đêm',
                        value: provider.isDarkMode,
                        onChanged: (_) => context.read<AppProvider>().toggleDarkMode(),
                        primary: primary,
                      ),
                      
                      _SettingSwitch(
                        icon: Icons.blur_on_rounded,
                        label: 'Hiệu ứng Liquid Glass',
                        subtitle: 'Blur, 3D, Animations',
                        value: provider.isLiquidEffects,
                        onChanged: (_) => context.read<AppProvider>().toggleLiquidEffects(),
                        primary: primary,
                      ),
                      
                      _SettingSwitch(
                        icon: Icons.sync_rounded,
                        label: 'Tự động làm mới',
                        subtitle: 'Cập nhật dữ liệu tự động',
                        value: provider.isAutoRefresh,
                        onChanged: (_) => context.read<AppProvider>().toggleAutoRefresh(),
                        primary: primary,
                      ),

                      // Event toggle if there's an active event
                      if (provider.currentEvent != SpecialEvent.none)
                        _SettingSwitch(
                          icon: Icons.celebration_rounded,
                          label: 'Chế độ sự kiện',
                          subtitle: AppTheme.getEventTitle(provider.currentEvent),
                          value: provider.eventThemeEnabled,
                          onChanged: (_) => context.read<AppProvider>().toggleEventTheme(),
                          primary: primary,
                        ),
                      
                      const SizedBox(height: 18),
                      _Divider(isDark: isDark),
                      const SizedBox(height: 18),
                      
                      // Version info
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.water_drop_rounded, color: primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Liquid OS Flutter',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'v5.0 • Made with ❤️',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.55)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.55),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: isDark 
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.06),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color primary;

  const _SettingSwitch({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: value
              ? primary.withOpacity(0.10)
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? primary.withOpacity(0.18)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: value
                    ? primary.withOpacity(0.18)
                    : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: value ? primary : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.45),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: value ? primary : null,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.38),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 26,
              decoration: BoxDecoration(
                color: value
                    ? primary
                    : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Align(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
