import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  // Theme settings
  AppColorTheme _colorTheme = AppColorTheme.blue;
  bool _isDarkMode = false;
  bool _isLiquidEffects = true;
  bool _isAutoRefresh = false;
  SpecialEvent _currentEvent = SpecialEvent.none;
  bool _eventThemeEnabled = true;

  // Data
  List<BTVN> _btvnList = [];
  List<TKB> _tkbList = [];
  List<ChangelogItem> _changelog = [];
  List<NotificationItem> _notifications = [];
  
  bool _isLoading = false;
  int _displayDay = 1;
  List<String> _tomorrowSubjects = [];

  // Getters
  AppColorTheme get colorTheme => _colorTheme;
  bool get isDarkMode => _isDarkMode;
  bool get isLiquidEffects => _isLiquidEffects;
  bool get isAutoRefresh => _isAutoRefresh;
  SpecialEvent get currentEvent => _eventThemeEnabled ? _currentEvent : SpecialEvent.none;
  bool get eventThemeEnabled => _eventThemeEnabled;
  bool get hasActiveEvent => _currentEvent != SpecialEvent.none && _eventThemeEnabled;
  
  List<BTVN> get btvnList => _btvnList;
  List<TKB> get tkbList => _tkbList;
  List<ChangelogItem> get changelog => _changelog;
  List<NotificationItem> get notifications => _notifications;
  
  bool get isLoading => _isLoading;
  int get displayDay => _displayDay;
  List<String> get tomorrowSubjects => _tomorrowSubjects;

  /// Initialize provider and load saved settings
  Future<void> initialize() async {
    await _loadSettings();
    _checkSpecialEvents();
    await _calculateDisplayDay();
    await refreshData();
  }

  /// Check for special events
  void _checkSpecialEvents() {
    _currentEvent = AppTheme.getCurrentEvent();
    notifyListeners();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeIndex = prefs.getInt('colorTheme') ?? 0;
    _colorTheme = AppColorTheme.values[themeIndex.clamp(0, 3)];
    
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isLiquidEffects = prefs.getBool('isLiquidEffects') ?? true;
    _isAutoRefresh = prefs.getBool('isAutoRefresh') ?? false;
    _eventThemeEnabled = prefs.getBool('eventThemeEnabled') ?? true;
    
    notifyListeners();
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorTheme', _colorTheme.index);
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('isLiquidEffects', _isLiquidEffects);
    await prefs.setBool('isAutoRefresh', _isAutoRefresh);
    await prefs.setBool('eventThemeEnabled', _eventThemeEnabled);
  }

  /// Calculate display day (tomorrow's day index)
  Future<void> _calculateDisplayDay() async {
    final now = DateTime.now();
    int day = now.weekday; // 1 = Monday, 7 = Sunday
    
    // If after 4 PM, show tomorrow's schedule
    if (now.hour >= 16) day++;
    
    // Weekend -> show Monday
    if (day >= 6) day = 1;
    
    _displayDay = day;
    
    // Calculate tomorrow's subjects for highlighting
    _tomorrowSubjects = _tkbList
        .where((t) => t.day == _displayDay)
        .map((t) => t.subject.toLowerCase())
        .toList();
  }

  /// Refresh all data from Supabase
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        SupabaseService.fetchBTVN(),
        SupabaseService.fetchTKB(),
        SupabaseService.fetchChangelog(),
        SupabaseService.fetchNotifications(),
      ]);

      _btvnList = results[0] as List<BTVN>;
      _tkbList = results[1] as List<TKB>;
      _changelog = results[2] as List<ChangelogItem>;
      _notifications = results[3] as List<NotificationItem>;

      await _calculateDisplayDay();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set color theme
  void setColorTheme(AppColorTheme theme) {
    _colorTheme = theme;
    _saveSettings();
    notifyListeners();
  }

  /// Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveSettings();
    notifyListeners();
  }

  /// Toggle liquid effects
  void toggleLiquidEffects() {
    _isLiquidEffects = !_isLiquidEffects;
    _saveSettings();
    notifyListeners();
  }

  /// Toggle auto refresh
  void toggleAutoRefresh() {
    _isAutoRefresh = !_isAutoRefresh;
    _saveSettings();
    notifyListeners();
  }

  /// Toggle event theme
  void toggleEventTheme() {
    _eventThemeEnabled = !_eventThemeEnabled;
    _saveSettings();
    notifyListeners();
  }

  /// Get BTVN grouped by subject
  Map<String, List<BTVN>> get btvnGrouped {
    final grouped = <String, List<BTVN>>{};
    for (final item in _btvnList) {
      if (!grouped.containsKey(item.subject)) {
        grouped[item.subject] = [];
      }
      grouped[item.subject]!.add(item);
    }
    return grouped;
  }

  /// Check if subject is for tomorrow
  bool isSubjectForTomorrow(String subject) {
    final subjectLower = subject.toLowerCase();
    return _tomorrowSubjects.any((t) => 
      subjectLower.contains(t) || t.contains(subjectLower)
    );
  }

  /// Get TKB for a specific day
  List<TKB> getTKBForDay(int day) {
    return _tkbList.where((t) => t.day == day).toList()
      ..sort((a, b) => a.tiet.compareTo(b.tiet));
  }

  /// Get duty text for a day
  String? getDutyForDay(int day) {
    final dayItems = getTKBForDay(day);
    final dutyItem = dayItems.firstWhere(
      (t) => t.truc != null && t.truc!.isNotEmpty && t.truc != 'Null' && t.truc != 'null',
      orElse: () => TKB(day: day, buoi: '', tiet: 0, subject: ''),
    );
    final truc = dutyItem.truc;
    if (truc == null || truc.isEmpty || truc == 'Null' || truc == 'null' || truc == 'Không trực') {
      return null;
    }
    return truc;
  }

  /// Get subject icon
  IconData getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('toán')) return Icons.calculate_rounded;
    if (s.contains('văn')) return Icons.edit_note_rounded;
    if (s.contains('anh')) return Icons.language_rounded;
    if (s.contains('khtn') || s.contains('lý') || s.contains('hóa') || s.contains('sinh')) {
      return Icons.science_rounded;
    }
    if (s.contains('sử') || s.contains('địa') || s.contains('khxh')) {
      return Icons.public_rounded;
    }
    if (s.contains('tin')) return Icons.computer_rounded;
    if (s.contains('thể') || s.contains('td')) return Icons.sports_soccer_rounded;
    if (s.contains('nhạc')) return Icons.music_note_rounded;
    if (s.contains('mĩ') || s.contains('họa')) return Icons.palette_rounded;
    if (s.contains('công nghệ') || s.contains('cn')) return Icons.build_rounded;
    if (s.contains('gdcd') || s.contains('đạo đức')) return Icons.psychology_rounded;
    if (s.contains('chào cờ')) return Icons.flag_rounded;
    if (s.contains('shcn') || s.contains('sinh hoạt')) return Icons.groups_rounded;
    return Icons.menu_book_rounded;
  }

  /// Get subject color
  Color getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('toán')) return const Color(0xFF4FACFE);
    if (s.contains('văn')) return const Color(0xFFFF6B6B);
    if (s.contains('anh')) return const Color(0xFFFFD93D);
    if (s.contains('khtn') || s.contains('lý') || s.contains('hóa') || s.contains('sinh')) {
      return const Color(0xFF6BCB77);
    }
    if (s.contains('sử') || s.contains('địa') || s.contains('khxh')) {
      return const Color(0xFFA66CFF);
    }
    if (s.contains('tin')) return const Color(0xFF00D9FF);
    if (s.contains('thể') || s.contains('td')) return const Color(0xFFFF8C00);
    return const Color(0xFF9B59B6);
  }
}
