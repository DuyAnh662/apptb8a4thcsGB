import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

import '../config/env.dart';

class SupabaseService {
  static const String _supabaseUrl = Env.supabaseUrl;
  static const String _supabaseKey = Env.supabaseKey;

  static final Map<String, String> _headers = {
    'apikey': _supabaseKey,
    'Authorization': 'Bearer $_supabaseKey',
    'Content-Type': 'application/json',
  };

  /// Initialize Supabase (no-op for HTTP version)
  static Future<void> initialize() async {
    // Using direct HTTP calls, no initialization needed
  }

  /// Fetch all BTVN
  static Future<List<BTVN>> fetchBTVN() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/btvn?select=*'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => BTVN.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching BTVN: $e');
      return [];
    }
  }

  /// Fetch TKB ordered by tiet
  static Future<List<TKB>> fetchTKB() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/tkb?select=*&order=tiet.asc'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => TKB.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching TKB: $e');
      return [];
    }
  }

  /// Fetch changelog/updates
  static Future<List<ChangelogItem>> fetchChangelog() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/changelog?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => ChangelogItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching changelog: $e');
      return [];
    }
  }

  /// Fetch notification history
  static Future<List<NotificationItem>> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/notification?select=*&order=created_at.desc&limit=50'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => NotificationItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }
}
