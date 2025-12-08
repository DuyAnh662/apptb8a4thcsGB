import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  int _currentTabIndex = 0;
  
  List<Map<String, dynamic>> _btvnList = [];
  List<Map<String, dynamic>> _tkbList = [];
  List<Map<String, dynamic>> _changelog = [];
  List<Map<String, dynamic>> _notifications = [];

  // Subject list for dropdowns
  static const List<String> subjects = [
    'Toán học - Đại số',
    'Toán học - Hình học',
    'Ngữ văn',
    'Tiếng Anh',
    'Vật lý',
    'Hóa học',
    'Sinh học',
    'Lịch sử',
    'Địa lí',
    'GDCD',
    'Tin học',
    'Công nghệ',
    'GDTC',
    'GDĐP',
    'Mĩ thuật',
    'Âm nhạc',
    'HĐTN',
  ];

  // Shortcuts for text expansion
  static const Map<String, String> shortcuts = {
    'kbt': 'Không có bài tập',
    'tds': 'Toán học - Đại số',
    'thh': 'Toán học - Hình học',
    'nv': 'Ngữ văn',
    'ta': 'Tiếng Anh',
    'vl': 'Vật lý',
    'hh': 'Hóa học',
    'sh': 'Sinh học',
    'ls': 'Lịch sử',
    'dl': 'Địa lí',
    'gd': 'GDCD',
    'tin': 'Tin học',
    'cn': 'Công nghệ',
    'nhac': 'Âm nhạc',
    'mt': 'Mĩ thuật',
    'btvn': 'Bài tập về nhà: ',
    'KTBC': 'Kiểm tra bài cũ',
  };

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  int get currentTabIndex => _currentTabIndex;
  List<Map<String, dynamic>> get btvnList => _btvnList;
  List<Map<String, dynamic>> get tkbList => _tkbList;
  List<Map<String, dynamic>> get changelog => _changelog;
  List<Map<String, dynamic>> get notifications => _notifications;

  // Password hash (SHA-256 of "123456" - should match admin.js)
  static const String _passwordHash = '329fe68c81dcc05dec93329dd35760318da604549107ec7ccb81d3a7545f54f4';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('admin_dark_mode') ?? false;
    _isLoggedIn = prefs.getBool('admin_logged_in') ?? false;
    notifyListeners();
    
    if (_isLoggedIn) {
      await loadAllData();
    }
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_dark_mode', _isDarkMode);
    notifyListeners();
  }

  // Simple password check (hash comparison)
  Future<bool> login(String username, String password) async {
    if (username != 'admin') return false;
    
    // For simplicity, accept "admin" and "123456"
    // In production, use proper SHA-256 hashing
    if (password == '123456') {
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_logged_in', true);
      await loadAllData();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_logged_in', false);
    notifyListeners();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    final data = await AdminSupabaseService.fetchAllData();
    _btvnList = data['btvn'] ?? [];
    _tkbList = data['tkb'] ?? [];
    _changelog = data['changelog'] ?? [];
    _notifications = data['notifications'] ?? [];

    _isLoading = false;
    notifyListeners();
  }

  // BTVN Operations
  Future<bool> addBTVN(String subject, String content) async {
    final success = await AdminSupabaseService.addBTVN(subject, content);
    if (success) await loadAllData();
    return success;
  }

  Future<bool> overwriteBTVN(String subject, String content) async {
    final success = await AdminSupabaseService.overwriteBTVN(subject, content);
    if (success) await loadAllData();
    return success;
  }

  Future<bool> deleteBTVN(String id) async {
    final success = await AdminSupabaseService.deleteBTVN(id);
    if (success) await loadAllData();
    return success;
  }

  // TKB Operations
  Future<bool> updateTKB(int day, int tiet, String subject, String buoi, {String? truc}) async {
    final success = await AdminSupabaseService.updateTKB(day, tiet, subject, buoi, truc: truc);
    if (success) await loadAllData();
    return success;
  }

  Future<bool> updateTruc(int day, String truc) async {
    final success = await AdminSupabaseService.updateTruc(day, truc);
    if (success) await loadAllData();
    return success;
  }

  List<Map<String, dynamic>> getTKBForDay(int day) {
    return _tkbList.where((t) => t['day'] == day).toList()
      ..sort((a, b) => (a['tiet'] ?? 0).compareTo(b['tiet'] ?? 0));
  }

  // Changelog Operations
  Future<bool> addChangelog(String content) async {
    final success = await AdminSupabaseService.addChangelog(content);
    if (success) await loadAllData();
    return success;
  }

  Future<bool> replaceChangelog(String content) async {
    final success = await AdminSupabaseService.replaceChangelog(content);
    if (success) await loadAllData();
    return success;
  }

  // Notification Operations
  Future<bool> sendNotification(String title, String message) async {
    final success = await AdminSupabaseService.sendNotification(title, message);
    if (success) await loadAllData();
    return success;
  }

  // Text expansion helper
  String expandShortcuts(String text) {
    String result = text;
    shortcuts.forEach((key, value) {
      result = result.replaceAll(RegExp('\\b$key\\s', caseSensitive: false), '$value ');
    });
    return result;
  }
}
