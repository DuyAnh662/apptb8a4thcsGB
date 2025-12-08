import 'dart:ui';
import 'package:flutter/material.dart';

/// Simple Bottom dock matching PWA design
class BottomDock extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onSettings;
  final bool isRefreshing;
  final bool showRefresh;

  const BottomDock({
    super.key,
    required this.onRefresh,
    required this.onSettings,
    this.isRefreshing = false,
    this.showRefresh = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomPadding + 24,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: showRefresh ? 16 : 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF2A2A30).withOpacity(0.92),
                          const Color(0xFF1E1E23).withOpacity(0.92),
                        ]
                      : [
                          Colors.white.withOpacity(0.94),
                          Colors.white.withOpacity(0.90),
                        ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.white.withOpacity(0.50),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.35)
                        : Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showRefresh) ...[
                    _DockButton(
                      icon: Icons.sync_rounded,
                      onTap: onRefresh,
                      isLoading: isRefreshing,
                      isDark: isDark,
                      primary: primary,
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: isDark 
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08),
                    ),
                  ],
                  _DockButton(
                    icon: Icons.tune_rounded,
                    onTap: onSettings,
                    isDark: isDark,
                    primary: primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDark;
  final Color primary;

  const _DockButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: isDark
                        ? Colors.white.withOpacity(0.75)
                        : Colors.black.withOpacity(0.55),
                  ),
          ),
        ),
      ),
    );
  }
}
