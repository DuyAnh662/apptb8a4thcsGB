import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';

class TKBFullWeekModal extends StatelessWidget {
  const TKBFullWeekModal({super.key});

  static const _dayNames = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
  static const _dayEmojis = ['', '🌟', '✨', '💫', '🌙', '🎯', ''];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF2A2A30).withOpacity(0.98),
                          const Color(0xFF1E1E23).withOpacity(0.98),
                        ]
                      : [
                          Colors.white.withOpacity(0.96),
                          Colors.white.withOpacity(0.92),
                        ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
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
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_view_week_rounded, color: primary, size: 22),
                            const SizedBox(width: 10),
                            const Text(
                              'Thời khóa biểu tuần',
                              style: TextStyle(
                                fontSize: 18,
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
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Body
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: 5, // Mon to Fri
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final dayItems = provider.getTKBForDay(day);
                        if (dayItems.isEmpty) return const SizedBox.shrink();
                        
                        final dutyText = provider.getDutyForDay(day);
                        final isToday = day == provider.displayDay;
                        
                        final morning = dayItems.where((t) => 
                          !t.buoi.toLowerCase().contains('chiều') && t.tiet <= 5
                        ).toList();
                        final afternoon = dayItems.where((t) => 
                          t.buoi.toLowerCase().contains('chiều') || t.tiet > 5
                        ).toList();

                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 400 + index * 80),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(-30 * (1 - value), 0),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: GlassCard(
                            isHighlight: isToday,
                            badge: isToday ? '📍 Hôm nay' : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day header with duty
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isToday
                                                  ? [primary, primary.withOpacity(0.8)]
                                                  : [Colors.grey.shade600, Colors.grey.shade700],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: isToday
                                                ? [
                                                    BoxShadow(
                                                      color: primary.withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                _dayEmojis[day],
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _dayNames[day],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (dutyText != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.cleaning_services_rounded, size: 12, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            Text(
                                              dutyText,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                
                                // Morning
                                if (morning.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  _SessionLabel('☀️ Sáng', isDark),
                                  ...morning.map((t) => _TKBRow(item: t, provider: provider)),
                                ],
                                
                                // Afternoon
                                if (afternoon.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _SessionLabel('🌙 Chiều', isDark),
                                  ...afternoon.map((t) => _TKBRow(item: t, provider: provider)),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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

class _SessionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SessionLabel(this.label, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      margin: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _TKBRow extends StatelessWidget {
  final dynamic item;
  final AppProvider provider;

  const _TKBRow({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor = provider.getSubjectColor(item.subject);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  subjectColor.withOpacity(0.2),
                  subjectColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'T${item.tiet}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: subjectColor,
                ),
              ),
            ),
          ),
          Container(
            width: 2,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  subjectColor.withOpacity(0.5),
                  subjectColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Icon(
            provider.getSubjectIcon(item.subject),
            color: subjectColor,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.subject,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
