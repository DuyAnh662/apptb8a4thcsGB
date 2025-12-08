import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem('BTVN', Icons.edit_note_rounded, '📝'),
    _NavItem('TKB', Icons.calendar_month_rounded, '📅'),
    _NavItem('Changelog', Icons.article_rounded, '📜'),
    _NavItem('Thông báo', Icons.notifications_rounded, '🔔'),
    _NavItem('Dữ liệu', Icons.storage_rounded, '📊'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Row(
        children: [
          // Desktop Sidebar
          if (isDesktop)
            _buildSidebar(theme, isDark, provider),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(theme, isDark, provider, isDesktop),
                
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: provider.loadAllData,
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        _BTVNTab(provider: provider),
                        _TKBTab(provider: provider),
                        _ChangelogTab(provider: provider),
                        _NotificationTab(provider: provider),
                        _DataViewerTab(provider: provider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Mobile Bottom Navigation
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isSelected = _selectedIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? theme.primaryColor
                                      : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSidebar(ThemeData theme, bool isDark, AdminProvider provider) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with traffic lights style
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'System Settings',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Text(item.emoji, style: const TextStyle(fontSize: 18)),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? theme.primaryColor : null,
                      ),
                    ),
                    onTap: () => setState(() => _selectedIndex = index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
          
          // Footer actions
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(provider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                  onPressed: () => provider.toggleDarkMode(),
                  tooltip: 'Chế độ tối/sáng',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => provider.loadAllData(),
                  tooltip: 'Tải lại',
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  onPressed: () => _showLogoutDialog(context, provider),
                  tooltip: 'Đăng xuất',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool isDark, AdminProvider provider, bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, MediaQuery.of(context).padding.top + 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _navItems[_selectedIndex].label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (!isDesktop) ...[
            IconButton(
              icon: Icon(provider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 22),
              onPressed: () => provider.toggleDarkMode(),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 22, color: Colors.red),
              onPressed: () => _showLogoutDialog(context, provider),
            ),
          ],
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🔒', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Text('Đăng xuất'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.logout();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String emoji;
  _NavItem(this.label, this.icon, this.emoji);
}

// ======================== BTVN TAB ========================
class _BTVNTab extends StatefulWidget {
  final AdminProvider provider;
  const _BTVNTab({required this.provider});

  @override
  State<_BTVNTab> createState() => _BTVNTabState();
}

class _BTVNTabState extends State<_BTVNTab> {
  String? _selectedSubject;
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  void _showToast(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleAdd() async {
    if (_selectedSubject == null || _contentController.text.isEmpty) {
      _showToast('Vui lòng điền đầy đủ!', false);
      return;
    }
    setState(() => _isSubmitting = true);
    final expanded = widget.provider.expandShortcuts(_contentController.text);
    final success = await widget.provider.addBTVN(_selectedSubject!, expanded);
    setState(() => _isSubmitting = false);
    _showToast(success ? 'Thêm thành công!' : 'Thêm thất bại!', success);
    if (success) _contentController.clear();
  }

  Future<void> _handleOverwrite() async {
    if (_selectedSubject == null || _contentController.text.isEmpty) {
      _showToast('Vui lòng điền đầy đủ!', false);
      return;
    }
    setState(() => _isSubmitting = true);
    final expanded = widget.provider.expandShortcuts(_contentController.text);
    final success = await widget.provider.overwriteBTVN(_selectedSubject!, expanded);
    setState(() => _isSubmitting = false);
    _showToast(success ? 'Ghi đè thành công!' : 'Ghi đè thất bại!', success);
    if (success) _contentController.clear();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 700 ? 600.0 : double.infinity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject dropdown
                  Text('Môn học', style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(hintText: '-- Chọn môn --'),
                    items: AdminProvider.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedSubject = v),
                  ),
                  const SizedBox(height: 20),

                  // Content textarea
                  Text('Nội dung', style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập nội dung...\nGợi ý: kbt → Không có bài tập',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleAdd,
                          child: _isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('📝 Ghi đè'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _handleOverwrite,
                          child: const Text('➕ Thêm mới'),
                        ),
                      ),
                    ],
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

// ======================== TKB TAB ========================
class _TKBTab extends StatefulWidget {
  final AdminProvider provider;
  const _TKBTab({required this.provider});

  @override
  State<_TKBTab> createState() => _TKBTabState();
}

class _TKBTabState extends State<_TKBTab> {
  int _selectedDay = 1;
  String? _selectedTruc;
  bool _isSubmitting = false;
  
  // Subject selections for each period
  final Map<String, String> _periodSubjects = {};
  
  static const days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6'];
  static const trucs = ['Tổ 1', 'Tổ 2', 'Tổ 3', 'Tổ 4'];
  static const subjects = [
    'Nghỉ',
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
    'HĐTN',
    'GDĐP',
    'Mĩ thuật',
    'Âm nhạc',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize all periods with "Nghỉ"
    for (int i = 1; i <= 5; i++) {
      _periodSubjects['Sáng-$i'] = 'Nghỉ';
      _periodSubjects['Chiều-$i'] = 'Nghỉ';
    }
  }

  Future<void> _handleSaveTKB() async {
    if (_selectedTruc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Tổ trực!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool allSuccess = true;
    // Save each period that is not "Nghỉ"
    for (var entry in _periodSubjects.entries) {
      final parts = entry.key.split('-');
      final buoi = parts[0];
      final tiet = int.parse(parts[1]);
      final subject = entry.value;
      
      if (subject != 'Nghỉ') {
        final success = await widget.provider.updateTKB(
          _selectedDay, 
          tiet, 
          subject, 
          buoi, 
          truc: _selectedTruc,
        );
        if (!success) allSuccess = false;
      }
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allSuccess ? '✅ Lưu TKB thành công!' : '❌ Có lỗi xảy ra!'),
          backgroundColor: allSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildPeriodRow(String buoi, int tiet, ThemeData theme) {
    final key = '$buoi-$tiet';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Tiết $tiet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _periodSubjects[key],
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              items: subjects.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (v) => setState(() => _periodSubjects[key] = v ?? 'Nghỉ'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 700 ? 700.0 : double.infinity;
    final isWide = screenWidth > 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day & Truc selectors
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedDay,
                          decoration: const InputDecoration(labelText: 'Thứ'),
                          items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text(days[i]))),
                          onChanged: (v) => setState(() => _selectedDay = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTruc,
                          decoration: const InputDecoration(labelText: 'Tổ trực'),
                          items: trucs.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _selectedTruc = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _selectedTruc == null ? null : () async {
                        final success = await widget.provider.updateTruc(_selectedDay, _selectedTruc!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Cập nhật tổ trực thành công!' : 'Thất bại!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.group_rounded, size: 18),
                      label: const Text('Cập nhật mỗi Tổ Trực'),
                    ),
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Period selectors - Morning & Afternoon
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Morning
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('☀️', style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 8),
                                    Text('Sáng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              for (int i = 1; i <= 5; i++) _buildPeriodRow('Sáng', i, theme),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Afternoon
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🌙', style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 8),
                                    Text('Chiều', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              for (int i = 1; i <= 5; i++) _buildPeriodRow('Chiều', i, theme),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Morning
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('☀️', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Text('Sáng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (int i = 1; i <= 5; i++) _buildPeriodRow('Sáng', i, theme),
                        
                        const SizedBox(height: 20),
                        
                        // Afternoon
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🌙', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Text('Chiều', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (int i = 1; i <= 5; i++) _buildPeriodRow('Chiều', i, theme),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleSaveTKB,
                      icon: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 20),
                      label: const Text('💾 Lưu TKB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

// ======================== CHANGELOG TAB ========================
class _ChangelogTab extends StatefulWidget {
  final AdminProvider provider;
  const _ChangelogTab({required this.provider});

  @override
  State<_ChangelogTab> createState() => _ChangelogTabState();
}

class _ChangelogTabState extends State<_ChangelogTab> {
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  void _showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleAdd() async {
    if (_contentController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập nội dung!', false);
      return;
    }
    
    setState(() => _isSubmitting = true);
    print('Adding changelog: ${_contentController.text}');
    
    try {
      final success = await widget.provider.addChangelog(_contentController.text.trim());
      print('Add changelog result: $success');
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          _contentController.clear();
          _showMessage('Thêm thành công!', true);
        } else {
          _showMessage('Thêm thất bại!', false);
        }
      }
    } catch (e) {
      print('Changelog error: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage('Lỗi: $e', false);
      }
    }
  }

  Future<void> _handleReplace() async {
    if (_contentController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập nội dung!', false);
      return;
    }
    
    setState(() => _isSubmitting = true);
    print('Replacing changelog: ${_contentController.text}');
    
    try {
      final success = await widget.provider.replaceChangelog(_contentController.text.trim());
      print('Replace changelog result: $success');
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          _contentController.clear();
          _showMessage('Thay thế thành công!', true);
        } else {
          _showMessage('Thay thế thất bại!', false);
        }
      }
    } catch (e) {
      print('Changelog error: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage('Lỗi: $e', false);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 700 ? 600.0 : double.infinity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nội dung (Hỗ trợ gõ tắt)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(hintText: 'Nhập nội dung changelog...'),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleAdd,
                          child: _isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('📝 Ghi đè (Giữ cũ)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _handleReplace,
                          child: const Text('➕ Thêm mới (Xóa cũ)'),
                        ),
                      ),
                    ],
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

// ======================== NOTIFICATION TAB ========================
class _NotificationTab extends StatefulWidget {
  final AdminProvider provider;
  const _NotificationTab({required this.provider});

  @override
  State<_NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<_NotificationTab> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 700 ? 600.0 : double.infinity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('📢', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 10),
                          Text('Gửi Thông Báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Tiêu đề', hintText: 'Tiêu đề thông báo'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(labelText: 'Nội dung', hintText: 'Nội dung thông báo...'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : () async {
                            if (_titleController.text.isEmpty || _messageController.text.isEmpty) return;
                            setState(() => _isSubmitting = true);
                            final success = await widget.provider.sendNotification(
                              _titleController.text,
                              _messageController.text,
                            );
                            setState(() => _isSubmitting = false);
                            if (success && context.mounted) {
                              _titleController.clear();
                              _messageController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi thành công!')));
                            }
                          },
                          icon: _isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, size: 18),
                          label: const Text('🚀 Gửi ngay'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📋 Lịch sử thông báo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      if (widget.provider.notifications.isEmpty)
                        Center(child: Text('Chưa có thông báo', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))))
                      else
                        ...widget.provider.notifications.take(10).map((n) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(n['message'] ?? '', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================== DATA VIEWER TAB ========================
class _DataViewerTab extends StatelessWidget {
  final AdminProvider provider;
  const _DataViewerTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 700 ? 600.0 : double.infinity;

    final allData = {
      'btvn': provider.btvnList,
      'tkb': provider.tkbList,
      'changelog': provider.changelog,
      'notifications': provider.notifications,
    };
    final jsonString = const JsonEncoder.withIndent('  ').convert(allData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📊 Dữ liệu JSON', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      OutlinedButton.icon(
                        onPressed: () => provider.loadAllData(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Tải lại'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      jsonString,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
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
