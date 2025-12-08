import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/env.dart';

class AdminSupabaseService {
  static const String _supabaseUrl = Env.supabaseUrl;
  static const String _supabaseKey = Env.supabaseKey;

  static final Map<String, String> _headers = {
    'apikey': _supabaseKey,
    'Authorization': 'Bearer $_supabaseKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // ---------- BTVN ----------
  static Future<List<Map<String, dynamic>>> fetchBTVN() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/btvn?select=*'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addBTVN(String subject, String content) async {
    try {
      final body = {
        'subject': subject, 
        'content': content,
        'date': DateTime.now().toIso8601String(),
      };
      print('Adding BTVN: $body');
      
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/btvn'),
        headers: _headers,
        body: json.encode(body),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response.statusCode == 201;
    } catch (e) {
      print('BTVN Error: $e');
      return false;
    }
  }

  /// Ghi đè: Xóa tất cả BTVN của môn rồi thêm mới
  static Future<bool> overwriteBTVN(String subject, String content) async {
    try {
      // Delete existing entries for this subject
      await http.delete(
        Uri.parse('$_supabaseUrl/rest/v1/btvn?subject=eq.$subject'),
        headers: _headers,
      );
      // Add new entry
      return await addBTVN(subject, content);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteBTVN(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_supabaseUrl/rest/v1/btvn?id=eq.$id'),
        headers: _headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ---------- TKB ----------
  static Future<List<Map<String, dynamic>>> fetchTKB() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/tkb?select=*&order=tiet.asc'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateTKB(int day, int tiet, String subject, String buoi, {String? truc}) async {
    try {
      final body = {
        'day': day,
        'tiet': tiet,
        'subject': subject,
        'buoi': buoi,
        if (truc != null) 'truc': truc,
      };
      
      // Check if entry exists
      final existing = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/tkb?day=eq.$day&tiet=eq.$tiet'),
        headers: _headers,
      );
      
      if (existing.statusCode == 200) {
        final list = json.decode(existing.body) as List;
        if (list.isNotEmpty) {
          // Update existing
          final id = list[0]['id'];
          final response = await http.patch(
            Uri.parse('$_supabaseUrl/rest/v1/tkb?id=eq.$id'),
            headers: _headers,
            body: json.encode(body),
          );
          return response.statusCode == 200;
        }
      }
      
      // Insert new
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/tkb'),
        headers: _headers,
        body: json.encode(body),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateTruc(int day, String truc) async {
    try {
      final response = await http.patch(
        Uri.parse('$_supabaseUrl/rest/v1/tkb?day=eq.$day'),
        headers: _headers,
        body: json.encode({'truc': truc}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ---------- Changelog ----------
  static Future<List<Map<String, dynamic>>> fetchChangelog() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/changelog?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addChangelog(String content) async {
    try {
      print('Adding changelog to: $_supabaseUrl/rest/v1/changelog');
      print('Content: $content');
      
      // Field is 'text' not 'content' based on admin.js
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/changelog'),
        headers: _headers,
        body: json.encode({'text': content}),  // Changed from 'content' to 'text'
      );
      
      print('Changelog response status: ${response.statusCode}');
      print('Changelog response body: ${response.body}');
      
      // Accept both 200 and 201 as success
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Changelog exception: $e');
      return false;
    }
  }

  /// Thêm mới và xóa tất cả cũ
  static Future<bool> replaceChangelog(String content) async {
    try {
      // Delete all
      await http.delete(
        Uri.parse('$_supabaseUrl/rest/v1/changelog?id=neq.00000000-0000-0000-0000-000000000000'),
        headers: _headers,
      );
      // Add new
      return await addChangelog(content);
    } catch (e) {
      return false;
    }
  }

  // ---------- Notifications ----------
  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/notification?select=*&order=created_at.desc&limit=50'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> sendNotification(String title, String message, {String type = 'daily'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/notification'),
        headers: _headers,
        body: json.encode({
          'title': title,
          'message': message,
          'type': type,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ---------- All Data ----------
  static Future<Map<String, dynamic>> fetchAllData() async {
    final btvn = await fetchBTVN();
    final tkb = await fetchTKB();
    final changelog = await fetchChangelog();
    final notifications = await fetchNotifications();
    
    return {
      'btvn': btvn,
      'tkb': tkb,
      'changelog': changelog,
      'notifications': notifications,
    };
  }
}
