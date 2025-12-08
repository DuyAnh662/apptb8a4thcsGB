import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/bottom_dock.dart';
import 'settings_modal.dart';
import 'tkb_full_week_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  final List<String> _tabLabels = ['BTVN', 'TKB', 'Tin tức', 'Thông báo'];
  final List<IconData> _tabIcons = [
    Icons.auto_stories_rounded,
    Icons.calendar_month_rounded,
    Icons.campaign_rounded,
    Icons.notifications_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await context.read<AppProvider>().refreshData();
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingsModal(),
    );
  }

  void _showFullWeekTKB() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const TKBFullWeekModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final event = provider.hasActiveEvent ? provider.currentEvent : SpecialEvent.none;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate content width for web - max 500px for mobile-like experience
    final contentWidth = screenWidth > 600 ? 500.0 : screenWidth;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getBackground(provider.colorTheme, isDark, event: event),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Main content - centered for web
            SafeArea(
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(theme, provider),
                      
                      // Tab Bar
                      _buildTabBar(theme, isDark, provider),
                      
                      // Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBTVNTab(provider),
                            _buildTKBTab(provider),
                            _buildUpdatesTab(provider),
                            _buildNotificationsTab(provider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Dock
            BottomDock(
              onRefresh: _handleRefresh,
              onSettings: _showSettings,
              isRefreshing: _isRefreshing,
              showRefresh: !provider.isAutoRefresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppProvider provider) {
    final title = provider.hasActiveEvent
        ? AppTheme.getEventTitle(provider.currentEvent)
        : 'Bảng thông tin';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.appBarTheme.titleTextStyle,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Event toggle if active
              if (provider.currentEvent != SpecialEvent.none)
                IconButton(
                  icon: Icon(
                    provider.eventThemeEnabled
                        ? Icons.celebration_rounded
                        : Icons.celebration_outlined,
                    size: 22,
                    color: provider.eventThemeEnabled
                        ? theme.primaryColor
                        : null,
                  ),
                  onPressed: () => provider.toggleEventTheme(),
                  tooltip: 'Chế độ sự kiện',
                ),
              IconButton(
                icon: Icon(
                  provider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 22,
                ),
                onPressed: () => provider.toggleDarkMode(),
                tooltip: 'Chế độ tối/sáng',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.40),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.25),
          ),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: theme.primaryColor,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.50),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: List.generate(4, (index) => Tab(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_tabIcons[index], size: 20),
              const SizedBox(height: 3),
              Text(
                _tabLabels[index],
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildBTVNTab(AppProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (provider.btvnList.isEmpty) {
      return _buildEmptyState('Không có bài tập! 🎉', 'Hãy nghỉ ngơi đi nào~');
    }

    final grouped = provider.btvnGrouped;
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aNext = provider.isSubjectForTomorrow(a);
        final bNext = provider.isSubjectForTomorrow(b);
        if (aNext && !bNext) return -1;
        if (!aNext && bNext) return 1;
        return 0;
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final subject = sortedKeys[index];
        final items = grouped[subject]!;
        final isTomorrow = provider.isSubjectForTomorrow(subject);
        final subjectColor = provider.getSubjectColor(subject);

        return GlassCard(
          isHighlight: isTomorrow,
          badge: isTomorrow ? '⚡ Sắp học' : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: subjectColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      provider.getSubjectIcon(subject),
                      color: subjectColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: subjectColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: subjectColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items.length} bài',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: subjectColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...items.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(
                  left: 10,
                  top: entry.key == 0 ? 0 : 8,
                  bottom: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 7, right: 12),
                      decoration: BoxDecoration(
                        color: subjectColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTKBTab(AppProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    final dayItems = provider.getTKBForDay(provider.displayDay);
    final dutyText = provider.getDutyForDay(provider.displayDay);
    
    const dayNames = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
    final dayName = dayNames[provider.displayDay.clamp(0, 6)];
    final theme = Theme.of(context);

    final morning = dayItems.where((t) => 
      !t.buoi.toLowerCase().contains('chiều') && t.tiet <= 5
    ).toList();
    final afternoon = dayItems.where((t) => 
      t.buoi.toLowerCase().contains('chiều') || t.tiet > 5
    ).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      children: [
        // Day header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.80)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                dayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            if (dutyText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cleaning_services_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      dutyText,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 18),
        
        // Morning
        if (morning.isNotEmpty) ...[
          _buildSessionHeader('☀️ Buổi Sáng', theme),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: morning.asMap().entries.map((entry) => 
                _buildTKBRow(entry.value, provider, entry.key == morning.length - 1)
              ).toList(),
            ),
          ),
        ],
        
        // Afternoon
        if (afternoon.isNotEmpty) ...[
          _buildSessionHeader('🌙 Buổi Chiều', theme),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: afternoon.asMap().entries.map((entry) => 
                _buildTKBRow(entry.value, provider, entry.key == afternoon.length - 1)
              ).toList(),
            ),
          ),
        ],

        if (dayItems.isEmpty)
          GlassCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 50)),
                    const SizedBox(height: 14),
                    Text(
                      'Không có lịch học',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.60),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Full week button
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _showFullWeekTKB,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.80)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_view_week_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Xem cả tuần',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.60),
        ),
      ),
    );
  }

  Widget _buildTKBRow(TKB item, AppProvider provider, bool isLast) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjectColor = provider.getSubjectColor(item.subject);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast ? null : BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'T${item.tiet}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: subjectColor,
                ),
              ),
            ),
          ),
          Container(
            width: 3,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(
            provider.getSubjectIcon(item.subject),
            color: subjectColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.subject,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesTab(AppProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (provider.changelog.isEmpty) {
      return _buildEmptyState('Chưa có tin tức', 'Tin tức mới sẽ xuất hiện ở đây');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      itemCount: provider.changelog.length,
      itemBuilder: (context, index) {
        final item = provider.changelog[index];
        final theme = Theme.of(context);
        
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: theme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thông báo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                ),
              ),
              if (item.createdAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.40),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab(AppProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (provider.notifications.isEmpty) {
      return _buildEmptyState('Chưa có thông báo', 'Thông báo mới sẽ xuất hiện ở đây');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final item = provider.notifications[index];
        final theme = Theme.of(context);
        final time = item.createdAt != null
            ? '${item.createdAt!.day}/${item.createdAt!.month} ${item.createdAt!.hour}:${item.createdAt!.minute.toString().padLeft(2, '0')}'
            : '';

        return GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(item.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.70),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.40),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: ShimmerLoading(height: 110),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.50),
            ),
          ),
        ],
      ),
    );
  }
}
