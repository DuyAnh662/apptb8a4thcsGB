/// BTVN (Bài tập về nhà) model
class BTVN {
  final String? id;
  final String subject;
  final String content;
  final DateTime? date;

  BTVN({
    this.id,
    required this.subject,
    required this.content,
    this.date,
  });

  factory BTVN.fromJson(Map<String, dynamic> json) {
    return BTVN(
      id: json['id']?.toString(),
      subject: json['subject'] as String? ?? 'Khác',
      content: json['content'] as String? ?? json['note'] as String? ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
    );
  }
}

/// TKB (Thời khóa biểu) model
class TKB {
  final String? id;
  final int day;
  final String buoi;
  final int tiet;
  final String subject;
  final String? truc;

  TKB({
    this.id,
    required this.day,
    required this.buoi,
    required this.tiet,
    required this.subject,
    this.truc,
  });

  factory TKB.fromJson(Map<String, dynamic> json) {
    return TKB(
      id: json['id']?.toString(),
      day: (json['day'] is int) ? json['day'] : int.tryParse(json['day']?.toString() ?? '1') ?? 1,
      buoi: json['buoi'] as String? ?? 'Sáng',
      tiet: (json['tiet'] is int) ? json['tiet'] : int.tryParse(json['tiet']?.toString() ?? '1') ?? 1,
      subject: json['subject'] as String? ?? '',
      truc: json['truc'] as String? ?? json['truc_nhat'] as String?,
    );
  }
}

/// Changelog/Updates model
class ChangelogItem {
  final String? id;
  final String content;
  final DateTime? createdAt;

  ChangelogItem({
    this.id,
    required this.content,
    this.createdAt,
  });

  factory ChangelogItem.fromJson(Map<String, dynamic> json) {
    return ChangelogItem(
      id: json['id']?.toString(),
      content: json['content'] as String? ?? json['text'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }
}

/// Notification model
class NotificationItem {
  final String? id;
  final String title;
  final String message;
  final String? type;
  final String? url;
  final DateTime? createdAt;

  NotificationItem({
    this.id,
    required this.title,
    required this.message,
    this.type,
    this.url,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString(),
      title: json['title'] as String? ?? 'Thông báo',
      message: json['message'] as String? ?? json['content'] as String? ?? '',
      type: json['type'] as String?,
      url: json['url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }

  String get icon {
    switch (type) {
      case 'daily':
        return '📚';
      case 'event':
        return '🎉';
      case 'free':
        return '📢';
      default:
        return '📬';
    }
  }
}
